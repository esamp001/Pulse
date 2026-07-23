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
}

export default UserRepository;
