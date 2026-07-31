import db from '../database/db';
import type { User, CreateUserData } from '../types/user';

class UserRepository {
  async findByEmail(email: string): Promise<User | undefined> {
    return db<User>('users').where({ email }).first();
  }

  async findById(id: string): Promise<User | undefined> {
    return db<User>('users').where({ id }).first();
  }

  async create(userData: CreateUserData): Promise<User> {
    const [user] = (await db<User>('users')
      .insert({
        name: userData.name,
        email: userData.email,
        password_hash: userData.password_hash,
        rating: userData.rating || 1200,
      })
      .returning(['id', 'name', 'email', 'password_hash', 'rating', 'wins', 'losses', 'is_onboarded', 'primary_sport', 'avatar_url', 'created_at', 'updated_at'])) as User[];
    return user;
  }

  async updateOnboardingStatus(userId: string, data: { is_onboarded: boolean; name?: string; primary_sport?: string; rating?: number; avatar_url?: string }): Promise<User> {
    const updatePayload: Record<string, any> = {
      is_onboarded: data.is_onboarded,
      updated_at: new Date(),
    };
    
    if (data.name && data.name.trim().length > 0) updatePayload.name = data.name.trim();
    if (data.primary_sport) updatePayload.primary_sport = data.primary_sport;
    if (data.rating) updatePayload.rating = data.rating;
    if (data.avatar_url) updatePayload.avatar_url = data.avatar_url;

    const [updatedUser] = (await db<User>('users')
      .where({ id: userId })
      .update(updatePayload)
      .returning(['id', 'name', 'email', 'password_hash', 'rating', 'wins', 'losses', 'is_onboarded', 'primary_sport', 'avatar_url', 'created_at', 'updated_at'])) as User[];

    return updatedUser;
  }

  async updatePassword(userId: string, passwordHash: string): Promise<User> {
    const [updatedUser] = (await db<User>('users')
      .where({ id: userId })
      .update({
        password_hash: passwordHash,
        updated_at: new Date(),
      })
      .returning(['id', 'name', 'email', 'password_hash', 'rating', 'wins', 'losses', 'is_onboarded', 'primary_sport', 'avatar_url', 'created_at', 'updated_at'])) as User[];

    return updatedUser;
  }

  async searchUsers(query: string, excludeUserId?: string): Promise<Partial<User>[]> {
    
    let q = db('users')
      .select('id', 'name', 'email', 'rating', 'wins', 'losses', 'primary_sport', 'avatar_url');

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

    return q.limit(20);
  }

  async updateUserRatingAndStats(userId: string, newRating: number, isWinner: boolean): Promise<void> {
    const rawQuery = isWinner
      ? db('users').where({ id: userId }).update({
          rating: newRating,
          wins: db.raw('wins + 1'),
          updated_at: new Date(),
        })
      : db('users').where({ id: userId }).update({
          rating: newRating,
          losses: db.raw('losses + 1'),
          updated_at: new Date(),
        });
    await rawQuery;
  }
}

export default UserRepository;
