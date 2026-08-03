import db from '../database/db';
import type { Knex } from 'knex';
import type { User, CreateUserData, UserSportStat } from '../types/user';

class UserRepository {
  async findByEmail(email: string): Promise<User | undefined> {
    const user = await db<User>('users').where({ email }).first();
    if (!user) return undefined;
    return this.findById(user.id);
  }

  async findById(id: string, trx?: Knex.Transaction): Promise<User | undefined> {
    const conn = trx || db;
    const user = await conn<User>('users').where({ id }).first();
    if (!user) return undefined;

    const sportStats = await conn<UserSportStat>('user_sport_stats').where({ user_id: id });
    const sportRatings: Record<string, number> = {};
    const primaryKey = (user.primary_sport || 'pickleball').toLowerCase();
    let primaryStat = sportStats.find((s) => s.sport.toLowerCase() === primaryKey) || sportStats.find((s) => s.is_primary) || sportStats[0];

    for (const s of sportStats) {
      sportRatings[s.sport.toLowerCase()] = s.rating;
    }

    if (!primaryStat) {
      sportRatings[primaryKey] = 1200;
      primaryStat = {
        id: '',
        user_id: id,
        sport: primaryKey,
        rating: 1200,
        wins: 0,
        losses: 0,
        is_primary: true,
        created_at: new Date(),
        updated_at: new Date(),
      };
    }

    user.rating = primaryStat.rating;
    user.wins = primaryStat.wins;
    user.losses = primaryStat.losses;
    user.sport_ratings = sportRatings;
    user.sport_stats = sportStats;

    return user;
  }

  async getSportRatings(userId: string, trx?: Knex.Transaction): Promise<Record<string, number>> {
    const conn = trx || db;
    const rows = await conn('user_sport_stats')
      .where({ user_id: userId })
      .select('sport', 'rating');

    const result: Record<string, number> = {};
    for (const row of rows) {
      result[row.sport.toLowerCase()] = row.rating;
    }
    return result;
  }

  async upsertSportRatings(userId: string, sportRatings: Record<string, number>, primarySport?: string, trx?: Knex.Transaction): Promise<Record<string, number>> {
    const conn = trx || db;

    if (primarySport) {
      const targetPrimary = primarySport.toLowerCase().trim();
      if (targetPrimary) {
        await conn('user_sport_stats')
          .where({ user_id: userId })
          .update({ is_primary: false });
      }
    }

    for (const [sport, rating] of Object.entries(sportRatings)) {
      const sportKey = sport.toLowerCase().trim();
      if (!sportKey) continue;

      const isPrimary = primarySport ? sportKey === primarySport.toLowerCase().trim() : false;

      await conn('user_sport_stats')
        .insert({
          user_id: userId,
          sport: sportKey,
          rating: Number(rating) || 1200,
          is_primary: isPrimary,
          created_at: new Date(),
          updated_at: new Date(),
        })
        .onConflict(['user_id', 'sport'])
        .merge({
          rating: Number(rating) || 1200,
          is_primary: isPrimary,
          updated_at: new Date(),
        });
    }

    return this.getSportRatings(userId, conn as Knex.Transaction);
  }

  async create(userData: CreateUserData): Promise<User> {
    return db.transaction(async (trx) => {
      const [user] = (await trx<User>('users')
        .insert({
          name: userData.name,
          email: userData.email,
          password_hash: userData.password_hash,
        })
        .returning(['id', 'name', 'email', 'password_hash', 'is_onboarded', 'primary_sport', 'avatar_url', 'created_at', 'updated_at'])) as User[];

      const defaultSport = (user.primary_sport || 'pickleball').toLowerCase();
      const initialRating = userData.rating || 1200;
      const sportRatings = await this.upsertSportRatings(user.id, { [defaultSport]: initialRating }, defaultSport, trx);

      user.rating = initialRating;
      user.wins = 0;
      user.losses = 0;
      user.sport_ratings = sportRatings;

      return user;
    });
  }

  async updateOnboardingStatus(userId: string, data: { is_onboarded: boolean; name?: string; primary_sport?: string; rating?: number; sport_ratings?: Record<string, number>; avatar_url?: string }): Promise<User> {
    return db.transaction(async (trx) => {
      const updatePayload: Record<string, any> = {
        is_onboarded: data.is_onboarded,
        updated_at: new Date(),
      };
      
      if (data.name && data.name.trim().length > 0) updatePayload.name = data.name.trim();
      if (data.primary_sport) updatePayload.primary_sport = data.primary_sport;
      if (data.avatar_url) updatePayload.avatar_url = data.avatar_url;

      await trx<User>('users')
        .where({ id: userId })
        .update(updatePayload);

      const ratingsToSave = data.sport_ratings || {};
      if (data.primary_sport && data.rating) {
        ratingsToSave[data.primary_sport.toLowerCase()] = data.rating;
      }

      if (Object.keys(ratingsToSave).length > 0) {
        await this.upsertSportRatings(userId, ratingsToSave, data.primary_sport, trx);
      }

      const updatedUser = await this.findById(userId, trx);
      if (!updatedUser) throw new Error('User not found after onboarding update');
      return updatedUser;
    });
  }

  async updatePassword(userId: string, passwordHash: string): Promise<User> {
    await db<User>('users')
      .where({ id: userId })
      .update({
        password_hash: passwordHash,
        updated_at: new Date(),
      });

    const updatedUser = await this.findById(userId);
    if (!updatedUser) throw new Error('User not found after password update');
    return updatedUser;
  }

  async searchUsers(query: string, excludeUserId?: string): Promise<Partial<User>[]> {
    let q = db('users')
      .select('id', 'name', 'email', 'primary_sport', 'avatar_url');

    if (excludeUserId) {
      q = q.whereNot({ id: excludeUserId });
    }

    if (query && query.trim().length > 0) {
      const searchTerm = `%${query.trim().toLowerCase()}%`;
      q = q.where((builder) => {
        builder
          .whereRaw('LOWER(COALESCE(name, \'\')) LIKE ?', [searchTerm])
          .orWhereRaw('LOWER(COALESCE(email, \'\')) LIKE ?', [searchTerm]);
      });
    }

    const users = await q.limit(20);
    if (users.length === 0) return users;

    const userIds = users.map((u) => u.id).filter((id): id is string => Boolean(id));
    const allStats = await db<UserSportStat>('user_sport_stats').whereIn('user_id', userIds);

    for (const u of users) {
      if (u.id) {
        const userStats = allStats.filter((s) => s.user_id === u.id);
        const primaryKey = (u.primary_sport || 'pickleball').toLowerCase();
        const primaryStat = userStats.find((s) => s.sport.toLowerCase() === primaryKey) || userStats.find((s) => s.is_primary) || userStats[0];

        const sportRatings: Record<string, number> = {};
        for (const s of userStats) {
          sportRatings[s.sport.toLowerCase()] = s.rating;
        }
        if (Object.keys(sportRatings).length === 0) {
          sportRatings[primaryKey] = 1200;
        }

        u.rating = primaryStat ? primaryStat.rating : 1200;
        u.wins = primaryStat ? primaryStat.wins : 0;
        u.losses = primaryStat ? primaryStat.losses : 0;
        u.sport_ratings = sportRatings;
      }
    }

    return users;
  }

  async updateUserRatingAndStats(userId: string, sport: string, newRating: number, isWinner: boolean, trx?: Knex.Transaction): Promise<void> {
    const conn = trx || db;
    const sportKey = (sport || 'pickleball').toLowerCase().trim();

    const existing = await conn('user_sport_stats')
      .where({ user_id: userId, sport: sportKey })
      .first();

    if (existing) {
      await conn('user_sport_stats')
        .where({ user_id: userId, sport: sportKey })
        .update({
          rating: newRating,
          wins: isWinner ? db.raw('wins + 1') : db.raw('wins'),
          losses: isWinner ? db.raw('losses') : db.raw('losses + 1'),
          updated_at: new Date(),
        });
    } else {
      await conn('user_sport_stats').insert({
        user_id: userId,
        sport: sportKey,
        rating: newRating,
        wins: isWinner ? 1 : 0,
        losses: isWinner ? 0 : 1,
        is_primary: false,
        created_at: new Date(),
        updated_at: new Date(),
      });
    }
  }
}

export default UserRepository;
