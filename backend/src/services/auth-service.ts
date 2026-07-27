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

  private formatUserResponse(user: User): Omit<User, 'password_hash'> & { has_password: boolean } {
    const { password_hash, ...userWithoutPassword } = user;
    return {
      ...userWithoutPassword,
      has_password: Boolean(password_hash),
    };
  }

  async register(name: string, email: string, password?: string): Promise<{ user: ReturnType<AuthService['formatUserResponse']>; token: string }> {
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
    return { user: this.formatUserResponse(user), token };
  }

  async login(email: string, password?: string): Promise<{ user: ReturnType<AuthService['formatUserResponse']>; token: string }> {
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
    return { user: this.formatUserResponse(user), token };
  }

  async googleAuth(email: string, name: string): Promise<{ user: ReturnType<AuthService['formatUserResponse']>; token: string }> {
    let user = await this.userRepository.findByEmail(email);

    if (!user) {
      user = await this.userRepository.create({
        name,
        email,
      });
    }

    const token = this.generateToken(user.id);
    return { user: this.formatUserResponse(user), token };
  }

  async getProfile(userId: string): Promise<ReturnType<AuthService['formatUserResponse']>> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    return this.formatUserResponse(user);
  }

  async completeOnboarding(userId: string, payload: { primary_sport?: string; rating?: number; avatar_url?: string }): Promise<ReturnType<AuthService['formatUserResponse']>> {
    const user = await this.userRepository.updateOnboardingStatus(userId, { is_onboarded: true, ...payload });
    return this.formatUserResponse(user);
  }

  async updatePassword(userId: string, currentPassword?: string, newPassword?: string): Promise<ReturnType<AuthService['formatUserResponse']>> {
    if (!newPassword || newPassword.length < 6) {
      throw new Error('New password must be at least 6 characters long');
    }

    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    if (user.password_hash) {
      if (!currentPassword) {
        throw new Error('Current password is required');
      }
      const isPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);
      if (!isPasswordValid) {
        throw new Error('Invalid current password');
      }
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    const updatedUser = await this.userRepository.updatePassword(userId, newHash);
    return this.formatUserResponse(updatedUser);
  }

  private generateToken(userId: string): string {
    return jwt.sign({ userId }, config.jwtSecret, { expiresIn: config.jwtExpiresIn as jwt.SignOptions['expiresIn'] });
  }
}

export default AuthService;
