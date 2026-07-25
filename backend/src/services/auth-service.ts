import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import UserRepository from '../repositories/user-repository';
import { config } from '../config/env';
import type { User } from '../types/user';

class AuthService {
  private userRepository: UserRepository;

  constructor() {
    this.userRepository = new UserRepository();
  }

  async register(name: string, email: string, password?: string): Promise<{ user: Omit<User, 'password_hash'>; token: string }> {
    const existingUser = await this.userRepository.findByEmail(email);

    if (existingUser) {
      throw new Error('Email is already registered');
    }

    let passwordHash: string | undefined;
    
    if (password) {
      passwordHash = await bcrypt.hash(password, 10);
    }

    const user = await this.userRepository.create({
      name,
      email,
      password_hash: passwordHash,
    });

    const token = this.generateToken(user.id);
    const { password_hash, ...userWithoutPassword } = user;

    return { user: userWithoutPassword, token };
  }

  async login(email: string, password?: string): Promise<{ user: Omit<User, 'password_hash'>; token: string }> {
    const user = await this.userRepository.findByEmail(email);
    if (!user) {
      throw new Error('Invalid email or password');
    }

    if (password && user.password_hash) {
      const isPasswordValid = await bcrypt.compare(password, user.password_hash);
      if (!isPasswordValid) {
        throw new Error('Invalid email or password');
      }
    }

    const token = this.generateToken(user.id);
    const { password_hash, ...userWithoutPassword } = user;

    return { user: userWithoutPassword, token };
  }

  async googleAuth(email: string, name: string): Promise<{ user: Omit<User, 'password_hash'>; token: string }> {
    let user = await this.userRepository.findByEmail(email);

    if (!user) {
      user = await this.userRepository.create({
        name,
        email,
      });
    }

    const token = this.generateToken(user.id);
    const { password_hash, ...userWithoutPassword } = user;

    return { user: userWithoutPassword, token };
  }

  async getProfile(userId: string): Promise<Omit<User, 'password_hash'>> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    const { password_hash, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async completeOnboarding(userId: string,payload: { primary_sport?: string; rating?: number; avatar_url?: string }): Promise<Omit<User, 'password_hash'>> {
    const user = await this.userRepository.updateOnboardingStatus(userId, {is_onboarded: true,...payload});
    const { password_hash, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  private generateToken(userId: string): string {
    return jwt.sign({ userId }, config.jwtSecret, { expiresIn: config.jwtExpiresIn as jwt.SignOptions['expiresIn'],});
  }
}

export default AuthService;
