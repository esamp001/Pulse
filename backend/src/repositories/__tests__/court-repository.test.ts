import courtRepository from '../court-repository';
import db from '../../database/db';

jest.mock('../../database/db', () => {
  const mockDb: any = jest.fn();
  mockDb.transaction = jest.fn();
  mockDb.raw = jest.fn();
  return {
    __esModule: true,
    default: mockDb,
  };
});

describe('CourtRepository Transaction Unit Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('upsertReview', () => {
    const validCourtId = '11111111-1111-1111-1111-111111111111';
    const validUserId = '22222222-2222-2222-2222-222222222222';

    it('should reject invalid UUIDs before starting a database transaction', async () => {
      await expect(
        courtRepository.upsertReview('invalid-uuid', validUserId, true, 'Great court!')
      ).rejects.toThrow('Invalid court ID: invalid-uuid');

      expect(db.transaction).not.toHaveBeenCalled();
    });

    it('should execute inside db.transaction and coordinate vote and comment', async () => {
      const mockTrx: any = jest.fn();
      (db.transaction as jest.Mock).mockImplementation(async (callback) => {
        return await callback(mockTrx);
      });

      const spyUpsertVote = jest.spyOn(courtRepository, 'upsertVote').mockResolvedValue({
        id: 'rev-1',
        court_id: validCourtId,
        user_id: validUserId,
        is_liked: true,
        comment: null,
        created_at: new Date(),
        updated_at: new Date(),
      });

      const spyCreateComment = jest.spyOn(courtRepository, 'createComment').mockResolvedValue({
        id: 'comm-1',
        court_id: validCourtId,
        user_id: validUserId,
        comment: 'Nice court surface',
        created_at: new Date(),
        updated_at: new Date(),
      });

      const result = await courtRepository.upsertReview(validCourtId, validUserId, true, 'Nice court surface');

      expect(db.transaction).toHaveBeenCalledTimes(1);
      expect(spyUpsertVote).toHaveBeenCalledWith(validCourtId, validUserId, true, mockTrx);
      expect(spyCreateComment).toHaveBeenCalledWith(validCourtId, validUserId, 'Nice court surface', mockTrx);
      expect(result).toMatchObject({
        id: 'comm-1',
        is_liked: true,
        comment: 'Nice court surface',
      });

      spyUpsertVote.mockRestore();
      spyCreateComment.mockRestore();
    });

    it('should bubble up errors within the transaction so Knex triggers rollback', async () => {
      const mockTrx: any = jest.fn();
      (db.transaction as jest.Mock).mockImplementation(async (callback) => {
        return await callback(mockTrx);
      });

      const spyUpsertVote = jest.spyOn(courtRepository, 'upsertVote').mockResolvedValue({
        id: 'rev-1',
        court_id: validCourtId,
        user_id: validUserId,
        is_liked: true,
        comment: null,
        created_at: new Date(),
        updated_at: new Date(),
      });

      const spyCreateComment = jest.spyOn(courtRepository, 'createComment').mockRejectedValue(
        new Error('Database disk full')
      );

      await expect(
        courtRepository.upsertReview(validCourtId, validUserId, true, 'Nice court surface')
      ).rejects.toThrow('Database disk full');

      expect(db.transaction).toHaveBeenCalledTimes(1);

      spyUpsertVote.mockRestore();
      spyCreateComment.mockRestore();
    });
  });
});
