import type { Response } from 'express';
import { z } from 'zod';
import MatchService from '../services/match-service';
import type { AuthenticatedRequest } from '../middleware/auth-middleware';

const createMatchSchema = z.object({
  sport: z.enum(['pickleball', 'tennis', 'table_tennis'], {
    errorMap: () => ({ message: 'Sport must be pickleball, tennis, or table_tennis' }),
  }),
  venue_name: z.string().min(1, 'Venue name is required'),
  location: z.string().optional(),
  scheduled_at: z.string().min(1, 'Scheduled date/time is required'),
});

class MatchController {
  private matchService: MatchService;

  constructor() {
    this.matchService = new MatchService();
  }

  createMatch = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;

      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const validation = createMatchSchema.safeParse(req.body);

      if (!validation.success) {
        res.status(400).json({ error: validation.error.errors[0].message });
        return;
      }

      const match = await this.matchService.createMatch(userId, validation.data);

      res.status(201).json({
        message: 'Match created successfully',
        data: match,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to create match' });
    }
  };

  getMatchById = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      const match = await this.matchService.getMatchById(id);

      res.status(200).json({ data: match });
    } catch (error: any) {
      res.status(404).json({ error: error.message || 'Match not found' });
    }
  };

  getUserMatches = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const matches = await this.matchService.getUserMatches(userId);
      res.status(200).json({ data: matches });
    } catch (error: any) {
      res.status(500).json({ error: error.message || 'Failed to fetch matches' });
    }
  };

  assignParticipant = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id } = req.params;
      const { role, user_id } = req.body;

      if (!role || (role !== 'player2' && role !== 'scorer')) {
        res.status(400).json({ error: 'Role must be player2 or scorer' });
        return;
      }

      if (!user_id) {
        res.status(400).json({ error: 'user_id is required' });
        return;
      }

      const match = await this.matchService.assignParticipant(id, userId, role, user_id);

      res.status(200).json({
        message: 'Participant assigned successfully',
        data: match,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to assign participant' });
    }
  };

  searchUsers = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const query = (req.query.q as string) || '';
      const users = await this.matchService.searchUsers(query, userId);

      res.status(200).json({ data: users });
    } catch (error: any) {
      res.status(500).json({ error: error.message || 'Failed to search users' });
    }
  };

  getActiveMatch = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const activeMatch = await this.matchService.getActiveMatch(userId);
      res.status(200).json({ data: activeMatch });
    } catch (error: any) {
      res.status(500).json({ error: error.message || 'Failed to fetch active match' });
    }
  };

  exitMatch = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id } = req.params;
      const result = await this.matchService.exitMatch(id, userId);

      res.status(200).json({
        message: result.action === 'cancelled' ? 'Match lobby cancelled successfully' : 'Left match lobby successfully',
        data: result,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to exit match room' });
    }
  };
}

export default MatchController;
