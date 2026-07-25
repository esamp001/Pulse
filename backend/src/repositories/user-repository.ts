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
    const [user] = await db<User>('users')
      .insert({
        name: userData.name,
        email: userData.email,
        password_hash: userData.password_hash,
        rating: userData.rating || 1200,
      })
      .returning('*');
    return user;
  }

  async updateOnboardingStatus(userId: string,data: { is_onboarded: boolean; primary_sport?: string; rating?: number; avatar_url?: string }): Promise<User> {

    const updatePayload: Record<string, any> = {is_onboarded: data.is_onboarded, updated_at: new Date(),
    };
    
    if (data.primary_sport) updatePayload.primary_sport = data.primary_sport;
    if (data.rating) updatePayload.rating = data.rating;
    if (data.avatar_url) updatePayload.avatar_url = data.avatar_url;

    const [updatedUser] = await db<User>('users').where({ id: userId }).update(updatePayload).returning('*');

    return updatedUser;
  }
}

export default UserRepository;
