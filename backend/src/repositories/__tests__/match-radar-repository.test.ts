import MatchRepository from '../match-repository';
import db from '../../database/db';

jest.mock('../../database/db', () => {
  const mockDb: any = jest.fn();
  mockDb.raw = jest.fn();
  mockDb.transaction = jest.fn(async (cb: any) => cb(jest.fn()));
  return {
    __esModule: true,
    default: mockDb,
  };
});

describe('MatchRadar / Open Matches Repository Unit Tests', () => {
  let repository: MatchRepository;

  beforeEach(() => {
    jest.clearAllMocks();
    repository = new MatchRepository();
  });

  describe('findOpenMatches', () => {
    it('should query open matches and calculate distance when coordinates are provided', async () => {
      const mockMatches = [
        {
          id: 'm1',
          creator_id: 'u1',
          player1_id: 'u1',
          sport: 'pickleball',
          status: 'WAITING',
          scheduled_at: new Date(),
          venue_name: 'BGC Pickleball Club',
          court_id: 'court-1',
        },
      ];

      const queryBuilder: any = {
        where: jest.fn().mockReturnThis(),
        whereNull: jest.fn().mockReturnThis(),
        whereRaw: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue(mockMatches),
      };

      (db as unknown as jest.Mock).mockReturnValue(queryBuilder);

      // Mock findByIdWithDetails
      jest.spyOn(repository, 'findByIdWithDetails').mockResolvedValue({
        id: 'm1',
        creator_id: 'u1',
        player1_id: 'u1',
        player2_id: null,
        player2_accepted: false,
        match_type: 'singles',
        team1_partner_accepted: false,
        team2_partner_accepted: false,
        scorer_accepted: false,
        sport: 'pickleball',
        status: 'WAITING',
        total_sets: 3,
        points_to_win_set: 11,
        win_by_two: true,
        venue_name: 'BGC Pickleball Club',
        court_id: 'court-1',
        scheduled_at: new Date(),
        created_at: new Date(),
        updated_at: new Date(),
        court: {
          id: 'court-1',
          name: 'BGC Pickleball Club',
          latitude: 14.5500,
          longitude: 121.0500,
          sports: ['pickleball'],
        },
      } as any);

      const result = await repository.findOpenMatches({
        sport: 'pickleball',
        latitude: 14.5505,
        longitude: 121.0505,
        radiusKm: 10,
      });

      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('m1');
      expect(result[0].court?.distance_km).toBeDefined();
      expect(typeof result[0].court?.distance_km).toBe('number');
    });
  });

  describe('joinOpenMatch', () => {
    it('should throw an error if the user attempts to join their own match', async () => {
      const matchId = 'm1';
      const userId = 'u1';

      const queryBuilder: any = {
        where: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue({
          id: matchId,
          creator_id: userId,
          player1_id: userId,
          status: 'WAITING',
          player2_id: null,
        }),
      };
      (db as unknown as jest.Mock).mockReturnValue(queryBuilder);

      await expect(repository.joinOpenMatch(matchId, userId)).rejects.toThrow(
        'You cannot join your own match as an opponent'
      );
    });

    it('should throw an error if the match is not in WAITING status', async () => {
      const matchId = 'm1';
      const userId = 'u2';

      const queryBuilder: any = {
        where: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue({
          id: matchId,
          creator_id: 'u1',
          player1_id: 'u1',
          status: 'LIVE',
          player2_id: null,
        }),
      };
      (db as unknown as jest.Mock).mockReturnValue(queryBuilder);

      await expect(repository.joinOpenMatch(matchId, userId)).rejects.toThrow(
        'Match is not waiting for players (status: LIVE)'
      );
    });

    it('should atomically update match and transition to READY', async () => {
      const matchId = 'm1';
      const userId = 'u2';

      const firstQuery: any = {
        where: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue({
          id: matchId,
          creator_id: 'u1',
          player1_id: 'u1',
          status: 'WAITING',
          player2_id: null,
        }),
      };

      const updateQuery: any = {
        where: jest.fn().mockReturnThis(),
        whereNull: jest.fn().mockReturnThis(),
        update: jest.fn().mockResolvedValue(1),
      };

      (db as unknown as jest.Mock)
        .mockReturnValueOnce(firstQuery)
        .mockReturnValueOnce(updateQuery);

      jest.spyOn(repository, 'findByIdWithDetails').mockResolvedValue({
        id: matchId,
        creator_id: 'u1',
        player1_id: 'u1',
        player2_id: userId,
        player2_accepted: true,
        status: 'READY',
      } as any);

      const result = await repository.joinOpenMatch(matchId, userId);

      expect(result.status).toBe('READY');
      expect(result.player2_id).toBe(userId);
    });
  });
});
