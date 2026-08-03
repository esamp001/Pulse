import type { Response } from 'express';
import { z } from 'zod';
import MatchService from '../services/match-service';
import type { AuthenticatedRequest } from '../middleware/auth-middleware';
import { notifyUserActiveMatchUpdate } from '../sockets/socket-emitter';

const createMatchSchema = z.object({
  sport: z.enum(['pickleball', 'tennis', 'table_tennis'], {
    errorMap: () => ({ message: 'Sport must be pickleball, tennis, or table_tennis' }),
  }),
  venue_name: z.string().min(1, 'Venue name is required'),
  location: z.string().optional(),
  scheduled_at: z.string().min(1, 'Scheduled date/time is required'),
  total_sets: z.number().int().optional(),
  points_to_win_set: z.number().int().optional(),
  win_by_two: z.boolean().optional(),
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

      notifyUserActiveMatchUpdate([userId]);

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

      notifyUserActiveMatchUpdate([userId, user_id, match.creator_id, match.player1_id, match.player2_id, match.scorer_id]);

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

      notifyUserActiveMatchUpdate();

      res.status(200).json({
        message: result.action === 'cancelled' ? 'Match lobby cancelled successfully' : 'Left match lobby successfully',
        data: result,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to exit match room' });
    }
  };

  acceptInvitation = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id } = req.params;
      const match = await this.matchService.acceptInvitation(id, userId);

      notifyUserActiveMatchUpdate([userId, match.creator_id, match.player1_id, match.player2_id, match.scorer_id]);

      res.status(200).json({
        message: 'Match invitation accepted successfully',
        data: match,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to accept match invitation' });
    }
  };

  declineInvitation = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id } = req.params;
      const match = await this.matchService.declineInvitation(id, userId);

      notifyUserActiveMatchUpdate([userId, match.creator_id, match.player1_id, match.player2_id, match.scorer_id]);

      res.status(200).json({
        message: 'Match invitation declined successfully',
        data: match,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to decline match invitation' });
    }
  };

  kickParticipant = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id, role } = req.params;
      if (role !== 'player2' && role !== 'scorer') {
        res.status(400).json({ error: 'Role must be player2 or scorer' });
        return;
      }

      const match = await this.matchService.kickParticipant(id, userId, role as 'player2' | 'scorer');

      notifyUserActiveMatchUpdate([userId, match.creator_id, match.player1_id, match.player2_id, match.scorer_id]);

      res.status(200).json({
        message: 'Participant kicked successfully',
        data: match,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to kick participant' });
    }
  };

  updateStatus = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id } = req.params;
      const { status } = req.body;

      if (!status || !['WAITING', 'READY', 'LIVE', 'FINISHED', 'CONFIRMED'].includes(status)) {
        res.status(400).json({ error: 'Invalid match status' });
        return;
      }

      const match = await this.matchService.updateMatchStatus(id, userId, status);

      notifyUserActiveMatchUpdate([userId, match.creator_id, match.player1_id, match.player2_id, match.scorer_id]);

      res.status(200).json({
        message: `Match status updated to ${status}`,
        data: match,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to update match status' });
    }
  };

  finalizeMatch = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id } = req.params;
      const { winner_id, player1_sets_won, player2_sets_won } = req.body;

      if (!winner_id) {
        res.status(400).json({ error: 'winner_id is required' });
        return;
      }

      const match = await this.matchService.evaluateAndCompleteMatch(
        id,
        userId,
        winner_id,
        player1_sets_won ?? 0,
        player2_sets_won ?? 0
      );

      notifyUserActiveMatchUpdate([userId, match.creator_id, match.player1_id, match.player2_id, match.scorer_id]);

      res.status(200).json({
        message: 'Match completed and winner declared successfully',
        data: match,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Failed to finalize match' });
    }
  };
}

export default MatchController;

