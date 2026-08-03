import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import UserRepository from '../repositories/user-repository';
import notificationService from './notification-service';
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

    // Notification Trigger: Welcome Onboarding
    try {
      await notificationService.createNotification({
        userId: user.id,
        category: 'ACCOUNT',
        title: 'Welcome to Rally!',
        subtitle: `Welcome ${name}! Your athlete profile is ready. Start or join a verified match anytime.`,
      });
    } catch (_) {}

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
    const isNew = !user;

    if (!user) {
      user = await this.userRepository.create({
        name,
        email,
      });
    }

    // Notification Trigger: Social Auth / Welcome
    try {
      await notificationService.createNotification({
        userId: user.id,
        category: 'ACCOUNT',
        title: 'Signed In via Google',
        subtitle: `You are securely logged in as ${email}. Password setup is optional.`,
      });
    } catch (_) {}

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

  async completeOnboarding(userId: string, payload: { name?: string; primary_sport?: string; rating?: number; avatar_url?: string }): Promise<ReturnType<AuthService['formatUserResponse']>> {
    const user = await this.userRepository.updateOnboardingStatus(userId, { is_onboarded: true, ...payload });

    try {
      await notificationService.createNotification({
        userId,
        category: 'ACCOUNT',
        title: 'Welcome Onboarding Completed',
        subtitle: `Your profile for ${user.name} has been set up successfully.`,
      });
    } catch (_) {}

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

    const hadPassword = Boolean(user.password_hash);

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

    // Notification Trigger: Password Update / Created
    try {
      await notificationService.createNotification({
        userId,
        category: 'ACCOUNT',
        title: hadPassword ? 'Password Updated' : 'Rally Password Set',
        subtitle: hadPassword
          ? 'Your Rally account password was successfully updated.'
          : 'You set a password for email login. You can now log in with email/password.',
      });
    } catch (_) {}

    return this.formatUserResponse(updatedUser);
  }

  private generateToken(userId: string): string {
    return jwt.sign({ userId }, config.jwtSecret, { expiresIn: config.jwtExpiresIn as jwt.SignOptions['expiresIn'] });
  }
}

export default AuthService;
