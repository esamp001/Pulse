import MatchService from '../match-service';
import MatchRepository from '../../repositories/match-repository';
import UserRepository from '../../repositories/user-repository';
import notificationService from '../notification-service';
import db from '../../database/db';

jest.mock('../../database/db', () => {
  const mockDb: any = jest.fn();
  mockDb.transaction = jest.fn(async (cb: any) => {
    const mockTrx = jest.fn();
    return await cb(mockTrx);
  });
  return {
    __esModule: true,
    default: mockDb,
  };
});

jest.mock('../../repositories/match-repository');
jest.mock('../../repositories/user-repository');
jest.mock('../notification-service', () => ({
  __esModule: true,
  default: {
    createNotification: jest.fn().mockResolvedValue({ id: 'notif-1' }),
  },
}));

describe('MatchService Unit Tests', () => {
  let matchService: MatchService;
  let mockMatchRepo: jest.Mocked<MatchRepository>;
  let mockUserRepo: jest.Mocked<UserRepository>;

  const mockSport = 'pickleball';
  const mockMatchId = '11111111-1111-1111-1111-111111111111';

  beforeEach(() => {
    jest.clearAllMocks();
    matchService = new MatchService();
    mockMatchRepo = (matchService as any).matchRepository;
    mockUserRepo = (matchService as any).userRepository;
  });

  describe('calculateAndApplyElo (Doubles vs Singles)', () => {
    const p1 = {
      id: 'p1',
      name: 'Player 1',
      rating: 1200,
      sport_ratings: { pickleball: 1200 },
    };
    const p1Partner = {
      id: 'p1-partner',
      name: 'Partner 1',
      rating: 1200,
      sport_ratings: { pickleball: 1200 },
    };
    const p2 = {
      id: 'p2',
      name: 'Player 2',
      rating: 1200,
      sport_ratings: { pickleball: 1200 },
    };
    const p2Partner = {
      id: 'p2-partner',
      name: 'Partner 2',
      rating: 1200,
      sport_ratings: { pickleball: 1200 },
    };

    it('should calculate doubles Elo using team averages and update all 4 players', async () => {
      const doublesMatch: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        team1_partner_id: 'p1-partner',
        player2_id: 'p2',
        team2_partner_id: 'p2-partner',
        scorer_id: 'scorer-1',
        match_type: 'doubles',
        sport: 'pickleball',
      };

      mockMatchRepo.findById.mockResolvedValue(doublesMatch);
      mockMatchRepo.findByIdWithDetails.mockResolvedValue({ ...doublesMatch, status: 'CONFIRMED' });
      mockMatchRepo.updateParticipants.mockResolvedValue(undefined as any);

      mockUserRepo.findById.mockImplementation(async (id: string) => {
        if (id === 'p1') return p1 as any;
        if (id === 'p1-partner') return p1Partner as any;
        if (id === 'p2') return p2 as any;
        if (id === 'p2-partner') return p2Partner as any;
        return null;
      });

      mockUserRepo.updateUserRatingAndStats.mockResolvedValue(undefined as any);

      // Team 1 wins (winnerId is p1)
      const result = await matchService.evaluateAndCompleteMatch(
        mockMatchId,
        'scorer-1',
        'p1',
        2,
        0
      );

      // Verify db.transaction was called
      expect(db.transaction).toHaveBeenCalledTimes(1);

      // Verify all 4 players were updated: Team 1 wins (+16 Elo for evenly matched), Team 2 loses
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith(
        'p1',
        'pickleball',
        expect.any(Number),
        true,
        expect.anything()
      );
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith(
        'p1-partner',
        'pickleball',
        expect.any(Number),
        true,
        expect.anything()
      );
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith(
        'p2',
        'pickleball',
        expect.any(Number),
        false,
        expect.anything()
      );
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith(
        'p2-partner',
        'pickleball',
        expect.any(Number),
        false,
        expect.anything()
      );

      // Verify rating notifications dispatched to all 4 participants
      expect(notificationService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'p1',
          category: 'RATING',
          title: 'PICKLEBALL ELO Increased',
        })
      );
      expect(notificationService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'p1-partner',
          category: 'RATING',
          title: 'PICKLEBALL ELO Increased',
        })
      );
      expect(notificationService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'p2',
          category: 'RATING',
          title: 'PICKLEBALL ELO Updated',
        })
      );
      expect(notificationService.createNotification).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'p2-partner',
          category: 'RATING',
          title: 'PICKLEBALL ELO Updated',
        })
      );

      expect(result.ratingChange).toBe(16);
    });

    it('should respect the 100 rating minimum floor for losing doubles team', async () => {
      const lowRatedP1 = { ...p1, rating: 105, sport_ratings: { pickleball: 105 } };
      const lowRatedP1Partner = { ...p1Partner, rating: 105, sport_ratings: { pickleball: 105 } };
      const lowRatedP2 = { ...p2, rating: 105, sport_ratings: { pickleball: 105 } };
      const lowRatedP2Partner = { ...p2Partner, rating: 102, sport_ratings: { pickleball: 102 } };

      const doublesMatch: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        team1_partner_id: 'p1-partner',
        player2_id: 'p2',
        team2_partner_id: 'p2-partner',
        scorer_id: 'scorer-1',
        match_type: 'doubles',
        sport: 'pickleball',
      };

      mockMatchRepo.findById.mockResolvedValue(doublesMatch);
      mockMatchRepo.findByIdWithDetails.mockResolvedValue({ ...doublesMatch, status: 'CONFIRMED' });
      mockMatchRepo.updateParticipants.mockResolvedValue(undefined as any);

      mockUserRepo.findById.mockImplementation(async (id: string) => {
        if (id === 'p1') return lowRatedP1 as any;
        if (id === 'p1-partner') return lowRatedP1Partner as any;
        if (id === 'p2') return lowRatedP2 as any;
        if (id === 'p2-partner') return lowRatedP2Partner as any;
        return null;
      });

      await matchService.evaluateAndCompleteMatch(mockMatchId, 'scorer-1', 'p1', 2, 0);

      // Check that losing players' new rating did not drop below 100
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith(
        'p2',
        'pickleball',
        100,
        false,
        expect.anything()
      );
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith(
        'p2-partner',
        'pickleball',
        100,
        false,
        expect.anything()
      );
    });

    it('should preserve standard 1v1 singles Elo calculation when match_type is singles', async () => {
      const singlesMatch: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        player2_id: 'p2',
        scorer_id: 'scorer-1',
        match_type: 'singles',
        sport: 'pickleball',
      };

      mockMatchRepo.findById.mockResolvedValue(singlesMatch);
      mockMatchRepo.findByIdWithDetails.mockResolvedValue({ ...singlesMatch, status: 'CONFIRMED' });
      mockMatchRepo.updateParticipants.mockResolvedValue(undefined as any);

      mockUserRepo.findById.mockImplementation(async (id: string) => {
        if (id === 'p1') return p1 as any;
        if (id === 'p2') return p2 as any;
        return null;
      });

      await matchService.evaluateAndCompleteMatch(mockMatchId, 'scorer-1', 'p1', 2, 0);

      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledTimes(2);
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith('p1', 'pickleball', 1216, true, expect.anything());
      expect(mockUserRepo.updateUserRatingAndStats).toHaveBeenCalledWith('p2', 'pickleball', 1184, false, expect.anything());
    });
  });

  describe('acceptInvitation (Doubles Readiness Transitions)', () => {
    it('should keep match in WAITING status if not all 4 players and scorer have accepted in doubles', async () => {
      const matchWaiting: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        team1_partner_id: 'p1-partner',
        team1_partner_accepted: false,
        player2_id: 'p2',
        player2_accepted: true,
        team2_partner_id: 'p2-partner',
        team2_partner_accepted: true,
        scorer_id: 'scorer-1',
        scorer_accepted: true,
        match_type: 'doubles',
        sport: 'pickleball',
        status: 'WAITING',
      };

      mockMatchRepo.findById.mockResolvedValue(matchWaiting);
      mockMatchRepo.findByIdWithDetails.mockResolvedValue({ ...matchWaiting, status: 'WAITING' });
      mockUserRepo.findById.mockResolvedValue({
        id: 'p2-partner',
        name: 'Partner 2',
        sport_ratings: { pickleball: 1200 },
      } as any);

      await matchService.acceptInvitation(mockMatchId, 'p2-partner');

      // Still WAITING because p1-partner hasn't accepted yet
      expect(mockMatchRepo.updateParticipants).toHaveBeenCalledWith(
        mockMatchId,
        expect.objectContaining({
          status: 'WAITING',
          team2_partner_accepted: true,
        })
      );
    });

    it('should transition doubles match status to READY when all 4 players and scorer have accepted', async () => {
      const matchAlmostReady: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        team1_partner_id: 'p1-partner',
        team1_partner_accepted: false, // The last unaccepted participant
        player2_id: 'p2',
        player2_accepted: true,
        team2_partner_id: 'p2-partner',
        team2_partner_accepted: true,
        scorer_id: 'scorer-1',
        scorer_accepted: true,
        match_type: 'doubles',
        sport: 'pickleball',
        status: 'WAITING',
      };

      mockMatchRepo.findById.mockResolvedValue(matchAlmostReady);
      mockMatchRepo.findByIdWithDetails.mockResolvedValue({ ...matchAlmostReady, status: 'READY' });
      mockUserRepo.findById.mockResolvedValue({
        id: 'p1-partner',
        name: 'Partner 1',
        sport_ratings: { pickleball: 1200 },
      } as any);

      await matchService.acceptInvitation(mockMatchId, 'p1-partner');

      // All 4 players and scorer accepted -> transitions to READY
      expect(mockMatchRepo.updateParticipants).toHaveBeenCalledWith(
        mockMatchId,
        expect.objectContaining({
          status: 'READY',
          team1_partner_accepted: true,
        })
      );
    });

    it('should throw error if accepting user has not configured the match sport in preferences', async () => {
      const matchWaiting: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        team1_partner_id: 'p1-partner',
        match_type: 'doubles',
        sport: 'pickleball',
        status: 'WAITING',
      };

      mockMatchRepo.findById.mockResolvedValue(matchWaiting);
      mockUserRepo.findById.mockResolvedValue({
        id: 'p1-partner',
        name: 'Partner 1',
        sport_ratings: { tennis: 1200 }, // No pickleball
        primary_sport: 'tennis',
      } as any);

      await expect(
        matchService.acceptInvitation(mockMatchId, 'p1-partner')
      ).rejects.toThrow('Cannot accept invitation: You have not configured Pickleball in your sport preferences.');
    });
  });

  describe('switchRole & kickParticipant (Doubles Slot Management)', () => {
    it('should allow switching to an empty team1_partner slot in doubles', async () => {
      const match: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        team1_partner_id: null,
        player2_id: 'user-switch',
        player2_accepted: true,
        team2_partner_id: null,
        scorer_id: null,
        match_type: 'doubles',
        sport: 'pickleball',
        status: 'WAITING',
      };

      mockMatchRepo.findById.mockResolvedValue(match);
      mockMatchRepo.findByIdWithDetails.mockResolvedValue({ ...match, team1_partner_id: 'user-switch' });
      mockUserRepo.findById.mockResolvedValue({
        id: 'user-switch',
        name: 'Switcher',
        sport_ratings: { pickleball: 1200 },
      } as any);

      await matchService.switchRole(mockMatchId, 'user-switch', 'team1_partner');

      expect(mockMatchRepo.updateParticipants).toHaveBeenCalledWith(
        mockMatchId,
        expect.objectContaining({
          player2_id: null,
          player2_accepted: false,
          team1_partner_id: 'user-switch',
          team1_partner_accepted: true,
        })
      );
    });

    it('should allow host to kick a team partner and reset room status to WAITING', async () => {
      const matchReady: any = {
        id: mockMatchId,
        creator_id: 'p1',
        player1_id: 'p1',
        team1_partner_id: 'p1-partner',
        team1_partner_accepted: true,
        player2_id: 'p2',
        player2_accepted: true,
        team2_partner_id: 'p2-partner',
        team2_partner_accepted: true,
        scorer_id: 'scorer-1',
        scorer_accepted: true,
        match_type: 'doubles',
        sport: 'pickleball',
        status: 'READY',
      };

      mockMatchRepo.findById.mockResolvedValue(matchReady);
      mockMatchRepo.findByIdWithDetails.mockResolvedValue({ ...matchReady, status: 'WAITING' });

      await matchService.kickParticipant(mockMatchId, 'p1', 'team1_partner');

      expect(mockMatchRepo.updateParticipants).toHaveBeenCalledWith(
        mockMatchId,
        expect.objectContaining({
          team1_partner_id: null,
          team1_partner_accepted: false,
          status: 'WAITING',
        })
      );
    });
  });
});
