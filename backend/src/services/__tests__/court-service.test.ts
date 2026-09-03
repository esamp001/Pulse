import { CourtService } from '../court-service';
import courtRepository from '../../repositories/court-repository';

// Mock courtRepository
jest.mock('../../repositories/court-repository', () => ({
  __esModule: true,
  default: {
    findNearby: jest.fn(),
    createCourt: jest.fn(),
    getCourtReviews: jest.fn(),
    getCourtComments: jest.fn(),
    upsertFromOsm: jest.fn(),
    upsertReview: jest.fn(),
    deleteReview: jest.fn(),
    deleteComment: jest.fn(),
  },
}));

describe('CourtService Unit Tests', () => {
  let courtService: CourtService;

  beforeEach(() => {
    jest.clearAllMocks();
    courtService = new CourtService();
  });

  describe('getCourtReviews calculation logic', () => {
    const mockCourtId = '11111111-1111-1111-1111-111111111111';
    const mockUserId = 'user-123';

    it('should calculate 100% recommendation when all votes are positive', async () => {
      (courtRepository.getCourtReviews as jest.Mock).mockResolvedValue([
        { id: 'rev-1', court_id: mockCourtId, user_id: 'u1', is_liked: true },
        { id: 'rev-2', court_id: mockCourtId, user_id: 'u2', is_liked: true },
      ]);
      (courtRepository.getCourtComments as jest.Mock).mockResolvedValue([]);

      const result = await courtService.getCourtReviews(mockCourtId);

      expect(result.likesCount).toBe(2);
      expect(result.dislikesCount).toBe(0);
      expect(result.totalVotes).toBe(2);
      expect(result.recommendationPercent).toBe(100);
      expect(result.userVote).toBeNull();
    });

    it('should calculate 0% recommendation when there are zero votes', async () => {
      (courtRepository.getCourtReviews as jest.Mock).mockResolvedValue([]);
      (courtRepository.getCourtComments as jest.Mock).mockResolvedValue([]);

      const result = await courtService.getCourtReviews(mockCourtId);

      expect(result.likesCount).toBe(0);
      expect(result.dislikesCount).toBe(0);
      expect(result.totalVotes).toBe(0);
      expect(result.recommendationPercent).toBe(0);
    });

    it('should accurately calculate percentage when votes are mixed', async () => {
      (courtRepository.getCourtReviews as jest.Mock).mockResolvedValue([
        { id: 'rev-1', court_id: mockCourtId, user_id: 'u1', is_liked: true },
        { id: 'rev-2', court_id: mockCourtId, user_id: 'u2', is_liked: true },
        { id: 'rev-3', court_id: mockCourtId, user_id: 'u3', is_liked: true },
        { id: 'rev-4', court_id: mockCourtId, user_id: 'u4', is_liked: false },
      ]);
      (courtRepository.getCourtComments as jest.Mock).mockResolvedValue([]);

      const result = await courtService.getCourtReviews(mockCourtId);

      expect(result.likesCount).toBe(3);
      expect(result.dislikesCount).toBe(1);
      expect(result.totalVotes).toBe(4);
      expect(result.recommendationPercent).toBe(75); // 3 / 4 = 75%
    });

    it('should identify requesting user vote correctly', async () => {
      (courtRepository.getCourtReviews as jest.Mock).mockResolvedValue([
        { id: 'rev-1', court_id: mockCourtId, user_id: 'u1', is_liked: true },
        { id: 'rev-2', court_id: mockCourtId, user_id: mockUserId, is_liked: false },
      ]);
      (courtRepository.getCourtComments as jest.Mock).mockResolvedValue([]);

      const result = await courtService.getCourtReviews(mockCourtId, mockUserId);

      expect(result.userVote).toBe(false);
    });

    it('should format comments and correlate author votes', async () => {
      (courtRepository.getCourtReviews as jest.Mock).mockResolvedValue([
        { id: 'rev-1', court_id: mockCourtId, user_id: 'u1', is_liked: true },
        { id: 'rev-2', court_id: mockCourtId, user_id: 'u2', is_liked: false },
      ]);
      (courtRepository.getCourtComments as jest.Mock).mockResolvedValue([
        {
          id: 'c-1',
          court_id: mockCourtId,
          user_id: 'u1',
          user_name: 'Alice',
          user_avatar: 'https://pulse.app/alice.png',
          comment: 'Great pickleball court!',
          created_at: new Date(),
          updated_at: new Date(),
        },
        {
          id: 'c-2',
          court_id: mockCourtId,
          user_id: 'u2',
          user_name: 'Bob',
          user_avatar: null,
          comment: 'Too windy',
          created_at: new Date(),
          updated_at: new Date(),
        },
      ]);

      const result = await courtService.getCourtReviews(mockCourtId);

      expect(result.reviews).toHaveLength(2);
      expect(result.reviews[0].user_name).toBe('Alice');
      expect(result.reviews[0].is_liked).toBe(true);
      expect(result.reviews[1].user_name).toBe('Bob');
      expect(result.reviews[1].is_liked).toBe(false);
    });
  });

  describe('createCourt input validation', () => {
    it('should throw an error if court name is blank', async () => {
      await expect(
        courtService.createCourt('user-1', {
          name: '   ',
          latitude: 14.5995,
          longitude: 120.9842,
          sports: ['tennis'],
        })
      ).rejects.toThrow('Court name is required');
    });

    it('should throw an error if latitude or longitude is missing', async () => {
      await expect(
        courtService.createCourt('user-1', {
          name: 'Central Park Courts',
          latitude: (undefined as unknown) as number,
          longitude: 120.9842,
          sports: ['tennis'],
        })
      ).rejects.toThrow('Latitude and longitude are required');
    });

    it('should delegate valid court payload to repository with is_verified true', async () => {
      const mockCreated = {
        id: 'court-uuid-1',
        name: 'BGC Pickleball Club',
        latitude: 14.5547,
        longitude: 121.0494,
        sports: ['pickleball'],
        is_verified: true,
        created_by: 'user-1',
      };
      (courtRepository.createCourt as jest.Mock).mockResolvedValue(mockCreated);

      const result = await courtService.createCourt('user-1', {
        name: 'BGC Pickleball Club',
        latitude: 14.5547,
        longitude: 121.0494,
        sports: ['pickleball'],
      });

      expect(courtRepository.createCourt).toHaveBeenCalledWith({
        name: 'BGC Pickleball Club',
        latitude: 14.5547,
        longitude: 121.0494,
        sports: ['pickleball'],
        is_verified: true,
        created_by: 'user-1',
      });
      expect(result).toEqual(mockCreated);
    });
  });

  describe('Haversine distance & Bounding Box formula', () => {
    it('should calculate Haversine distance accurately between two coordinates', () => {
      // Manila (14.5995, 120.9842) to Quezon City (14.6760, 121.0437) ~10.4 km
      const lat1 = 14.5995;
      const lon1 = 120.9842;
      const lat2 = 14.6760;
      const lon2 = 121.0437;

      const toRad = (x: number) => (x * Math.PI) / 180;
      const R = 6371; // Earth radius in km

      const dLat = toRad(lat2 - lat1);
      const dLon = toRad(lon2 - lon1);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      const distance = R * c;

      expect(distance).toBeGreaterThan(9.5);
      expect(distance).toBeLessThan(11.5);
    });

    it('should compute appropriate bounding box deltas for nearby searches', () => {
      const radiusKm = 25;
      const lat = 14.5995;
      const latDelta = radiusKm / 111.0;
      const cosLat = Math.cos((lat * Math.PI) / 180.0);
      const lngDelta = radiusKm / (111.0 * Math.max(cosLat, 0.001));

      expect(latDelta).toBeCloseTo(0.225, 2);
      expect(lngDelta).toBeGreaterThan(latDelta); // Longitude degrees are narrower away from equator
      expect(lngDelta).toBeCloseTo(0.233, 2);
    });
  });
});
