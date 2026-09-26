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
  court_id: z.string().uuid().optional().nullable(),
  scheduled_at: z.string().min(1, 'Scheduled date/time is required'),
  match_type: z.enum(['singles', 'doubles']).optional(),
  total_sets: z.number().int().optional(),
  points_to_win_set: z.number().int().optional(),
  win_by_two: z.boolean().optional(),
});

class MatchController {
  private matchService: MatchService;

  constructor() {
    this.matchService = new MatchService();
  }

  private getMatchNotificationUserIds(userId: string, match: any, extraUserId?: string): string[] {
    const list = [
      userId,
      extraUserId,
      match.creator_id,
      match.player1_id,
      match.team1_partner_id,
      match.player2_id,
      match.team2_partner_id,
      match.scorer_id,
    ].filter((id): id is string => Boolean(id));
    return Array.from(new Set(list));
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

  joinMatchByPin = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { pin, role } = req.body;
      if (!pin) {
        res.status(400).json({ error: '6-digit PIN code is required' });
        return;
      }

      const match = await this.matchService.joinMatchByPin(userId, pin, role);
      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

      res.status(200).json({
        message: 'Successfully joined match via PIN',
        data: match,
      });
    } catch (error: any) {
      console.error('[MatchController joinMatchByPin Error]:', error);
      res.status(400).json({ error: error.message || 'Failed to join match by PIN' });
    }
  };

  switchRole = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }

      const { id } = req.params;
      const { target_role } = req.body;

      const VALID_SWITCH_ROLES = ['player1', 'team1_partner', 'player2', 'team2_partner', 'scorer'];
      if (!target_role || !VALID_SWITCH_ROLES.includes(target_role)) {
        res.status(400).json({ error: 'target_role must be player1, team1_partner, player2, team2_partner, or scorer' });
        return;
      }

      const match = await this.matchService.switchRole(id, userId, target_role);
      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

      res.status(200).json({
        message: 'Successfully switched role in match room',
        data: match,
      });
    } catch (error: any) {
      console.error('[MatchController switchRole Error]:', error);
      res.status(400).json({ error: error.message || 'Failed to switch role' });
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

      const VALID_ROLES = ['player2', 'scorer', 'team1_partner', 'team2_partner'];
      if (!role || !VALID_ROLES.includes(role)) {
        res.status(400).json({ error: 'Role must be player2, scorer, team1_partner, or team2_partner' });
        return;
      }

      if (!user_id) {
        res.status(400).json({ error: 'user_id is required' });
        return;
      }

      const match = await this.matchService.assignParticipant(id, userId, role, user_id);

      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match, user_id));

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

      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

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

      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

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
      const VALID_KICK_ROLES = ['player2', 'scorer', 'team1_partner', 'team2_partner'];
      if (!VALID_KICK_ROLES.includes(role)) {
        res.status(400).json({ error: 'Role must be player2, scorer, team1_partner, or team2_partner' });
        return;
      }

      const match = await this.matchService.kickParticipant(id, userId, role as any);

      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

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

      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

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
      const { winner_id, player1_sets_won, player2_sets_won, set_scores } = req.body;

      if (!winner_id) {
        res.status(400).json({ error: 'winner_id is required' });
        return;
      }

      const match = await this.matchService.evaluateAndCompleteMatch(
        id,
        userId,
        winner_id,
        player1_sets_won ?? 0,
        player2_sets_won ?? 0,
        set_scores
      );

      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

      res.status(200).json({
        message: 'Match completed and winner declared successfully',
        data: match,
      });
    } catch (error: any) {
      console.error('[MatchController finalizeMatch Error]:', error);
      res.status(400).json({ error: error.message || 'Failed to finalize match' });
    }
  };

  getOpenMatches = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const { sport, latitude, longitude, radiusKm, limit } = req.query;
      const matches = await this.matchService.getOpenMatches({
        sport: typeof sport === 'string' ? sport : undefined,
        latitude: latitude !== undefined ? parseFloat(latitude as string) : undefined,
        longitude: longitude !== undefined ? parseFloat(longitude as string) : undefined,
        radiusKm: radiusKm !== undefined ? parseFloat(radiusKm as string) : undefined,
        limit: limit !== undefined ? parseInt(limit as string, 10) : undefined,
      });
      res.status(200).json({ matches });
    } catch (err: any) {
      console.error('[MatchController getOpenMatches Error]:', err);
      res.status(500).json({ error: err.message || 'Failed to fetch open matches' });
    }
  };

  joinOpenMatch = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized user' });
        return;
      }
      const { id } = req.params;
      const match = await this.matchService.joinOpenMatch(id, userId);

      notifyUserActiveMatchUpdate(this.getMatchNotificationUserIds(userId, match));

      res.status(200).json({
        message: 'Joined match successfully',
        match,
      });
    } catch (err: any) {
      console.error('[MatchController joinOpenMatch Error]:', err);
      const statusCode =
        err.message?.includes('not found') ||
        err.message?.includes('full') ||
        err.message?.includes('own match') ||
        err.message?.includes('already have an active match')
          ? 400
          : 500;
      res.status(statusCode).json({ error: err.message || 'Failed to join match' });
    }
  };
}

export default MatchController;


