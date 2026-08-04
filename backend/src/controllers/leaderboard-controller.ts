import type { Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth-middleware';
import { LeaderboardService } from '../services/leaderboard-service';
import type { LeaderboardCategory } from '../types/leaderboard';

export class LeaderboardController {
  private leaderboardService = new LeaderboardService();

  getLeaderboard = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const sport = (req.query.sport as string) || 'all';
      const category = ((req.query.category as string) || 'elo') as LeaderboardCategory;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;
      const offset = req.query.offset ? parseInt(req.query.offset as string, 10) : 0;
      const currentUserId = req.user?.userId;

      const result = await this.leaderboardService.getLeaderboard({
        sport,
        category,
        limit,
        offset,
        currentUserId,
      });

      res.status(200).json({
        message: 'Leaderboard fetched successfully',
        data: result,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message || 'Failed to fetch leaderboard' });
    }
  };
}
