import type { Request, Response } from 'express';
import { z } from 'zod';
import AuthService from '../services/auth-service';

const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters').optional(),
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required').optional(),
});

const googleAuthSchema = z.object({
  email: z.string().email('Invalid email address'),
  name: z.string().min(1, 'Name is required'),
});

class AuthController {
  private authService: AuthService;

  constructor() {
    this.authService = new AuthService();
  }

  // Registration endpoint
  register = async (req: Request, res: Response): Promise<void> => {
    try {
      const validation = registerSchema.safeParse(req.body);

      if (!validation.success) {
        res.status(400).json({ error: validation.error.errors[0].message });
        return;
      }

      const { name, email, password } = validation.data;
      
      const result = await this.authService.register(name, email, password);

      res.status(201).json({
        message: 'User registered successfully',
        data: result,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Registration failed' });
    }
  };

  login = async (req: Request, res: Response): Promise<void> => {
    try {
      const validation = loginSchema.safeParse(req.body);

      if (!validation.success) {
        res.status(400).json({ error: validation.error.errors[0].message });
        return;
      }

      const { email, password } = validation.data;

      const result = await this.authService.login(email, password);

      res.status(200).json({
        message: 'Login successful',
        data: result,
      });
    } catch (error: any) {
      res.status(401).json({ error: error.message || 'Login failed' });
    }
  };

  googleAuth = async (req: Request, res: Response): Promise<void> => {
    try {
      const validation = googleAuthSchema.safeParse(req.body);
      if (!validation.success) {
        res.status(400).json({ error: validation.error.errors[0].message });
        return;
      }

      const { email, name } = validation.data;
      const result = await this.authService.googleAuth(email, name);

      res.status(200).json({
        message: 'Google authentication successful',
        data: result,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Google authentication failed' });
    }
  };

  getMe = async (req: any, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const user = await this.authService.getProfile(userId);

      res.status(200).json({
        message: 'User profile retrieved successfully',
        data: { user },
      });
    } catch (error: any) {
      res.status(404).json({ error: error.message || 'User profile not found' });
    }
  };
}

export default AuthController;
