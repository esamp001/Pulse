import db from '../database/db';
import type { User, CreateUserData, UserSportStat } from '../types/user';

class UserRepository {
  async findByEmail(email: string): Promise<User | undefined> {
    const user = await db<User>('users').where({ email }).first();
    if (!user) return undefined;
    return this.findById(user.id);
  }

  async findById(id: string): Promise<User | undefined> {
    const user = await db<User>('users').where({ id }).first();
    if (!user) return undefined;

    const sportStats = await db<UserSportStat>('user_sport_stats').where({ user_id: id });
    const sportRatings: Record<string, number> = {};
    let primaryStat = sportStats.find((s) => s.is_primary || s.sport.toLowerCase() === (user.primary_sport || 'pickleball').toLowerCase()) || sportStats[0];

    for (const s of sportStats) {
      sportRatings[s.sport.toLowerCase()] = s.rating;
    }

    if (!primaryStat) {
      const primaryKey = (user.primary_sport || 'pickleball').toLowerCase();
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

  async getSportRatings(userId: string): Promise<Record<string, number>> {
    const rows = await db('user_sport_stats')
      .where({ user_id: userId })
      .select('sport', 'rating');

    const result: Record<string, number> = {};
    for (const row of rows) {
      result[row.sport.toLowerCase()] = row.rating;
    }
    return result;
  }

  async upsertSportRatings(userId: string, sportRatings: Record<string, number>, primarySport?: string): Promise<Record<string, number>> {
    for (const [sport, rating] of Object.entries(sportRatings)) {
      const sportKey = sport.toLowerCase().trim();
      if (!sportKey) continue;

      const isPrimary = primarySport ? sportKey === primarySport.toLowerCase().trim() : false;

      await db('user_sport_stats')
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

    return this.getSportRatings(userId);
  }

  async create(userData: CreateUserData): Promise<User> {
    const [user] = (await db<User>('users')
      .insert({
        name: userData.name,
        email: userData.email,
        password_hash: userData.password_hash,
      })
      .returning(['id', 'name', 'email', 'password_hash', 'is_onboarded', 'primary_sport', 'avatar_url', 'created_at', 'updated_at'])) as User[];

    const defaultSport = (user.primary_sport || 'pickleball').toLowerCase();
    const initialRating = userData.rating || 1200;
    const sportRatings = await this.upsertSportRatings(user.id, { [defaultSport]: initialRating }, defaultSport);

    user.rating = initialRating;
    user.wins = 0;
    user.losses = 0;
    user.sport_ratings = sportRatings;

    return user;
  }

  async updateOnboardingStatus(userId: string, data: { is_onboarded: boolean; name?: string; primary_sport?: string; rating?: number; sport_ratings?: Record<string, number>; avatar_url?: string }): Promise<User> {
    const updatePayload: Record<string, any> = {
      is_onboarded: data.is_onboarded,
      updated_at: new Date(),
    };
    
    if (data.name && data.name.trim().length > 0) updatePayload.name = data.name.trim();
    if (data.primary_sport) updatePayload.primary_sport = data.primary_sport;
    if (data.avatar_url) updatePayload.avatar_url = data.avatar_url;

    await db<User>('users')
      .where({ id: userId })
      .update(updatePayload);

    const ratingsToSave = data.sport_ratings || {};
    if (data.primary_sport && data.rating) {
      ratingsToSave[data.primary_sport.toLowerCase()] = data.rating;
    }

    if (Object.keys(ratingsToSave).length > 0) {
      await this.upsertSportRatings(userId, ratingsToSave, data.primary_sport);
    }

    const updatedUser = await this.findById(userId);
    if (!updatedUser) throw new Error('User not found after onboarding update');
    return updatedUser;
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

    for (const u of users) {
      if (u.id) {
        const stats = await this.findById(u.id);
        if (stats) {
          u.rating = stats.rating;
          u.wins = stats.wins;
          u.losses = stats.losses;
        }
      }
    }

    return users;
  }

  async updateUserRatingAndStats(userId: string, sport: string, newRating: number, isWinner: boolean): Promise<void> {
    const sportKey = (sport || 'pickleball').toLowerCase().trim();

    const existing = await db('user_sport_stats')
      .where({ user_id: userId, sport: sportKey })
      .first();

    if (existing) {
      await db('user_sport_stats')
        .where({ user_id: userId, sport: sportKey })
        .update({
          rating: newRating,
          wins: isWinner ? db.raw('wins + 1') : db.raw('wins'),
          losses: isWinner ? db.raw('losses') : db.raw('losses + 1'),
          updated_at: new Date(),
        });
    } else {
      await db('user_sport_stats').insert({
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
