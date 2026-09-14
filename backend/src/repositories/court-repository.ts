import { Knex } from 'knex';
import db from '../database/db';

export interface ICourtRow {
  id: string;
  osm_id: string | null;
  name: string;
  address: string | null;
  city: string | null;
  latitude: number;
  longitude: number;
  sports: string[] | string;
  surface: string | null;
  has_lighting: boolean;
  is_indoor: boolean;
  access_type: string;
  is_verified: boolean;
  created_by: string | null;
  image_url?: string | null;
  created_at: Date;
  updated_at: Date;
  distance_km?: number;
  likes_count?: number;
  dislikes_count?: number;
  user_vote?: boolean | null;
}

export interface IFindNearbyParams {
  latitude: number;
  longitude: number;
  radiusKm?: number;
  sport?: string;
  search?: string;
  limit?: number;
  userId?: string;
}

export interface ICreateCourtPayload {
  osm_id?: string | null;
  name: string;
  address?: string | null;
  city?: string | null;
  latitude: number;
  longitude: number;
  sports: string[];
  surface?: string | null;
  has_lighting?: boolean;
  is_indoor?: boolean;
  access_type?: string;
  is_verified?: boolean;
  created_by?: string | null;
  image_url?: string | null;
}

export interface ICourtReviewRow {
  id: string;
  court_id: string;
  user_id: string;
  is_liked: boolean;
  comment: string | null;
  created_at: Date;
  updated_at: Date;
  user_name?: string;
  user_avatar?: string | null;
}

export interface ICourtCommentRow {
  id: string;
  court_id: string;
  user_id: string;
  comment: string;
  created_at: Date;
  updated_at: Date;
  user_name?: string;
  user_avatar?: string | null;
}

class CourtRepository {
  async findNearby(params: IFindNearbyParams): Promise<ICourtRow[]> {
    try {
      const {
        latitude,
        longitude,
        radiusKm = 25,
        sport,
        search,
        limit = 50,
        userId,
      } = params;

      // Approximate bounding box to leverage latitude/longitude index
      const latDelta = radiusKm / 111.0;
      const cosLat = Math.cos((latitude * Math.PI) / 180.0);
      const lngDelta = radiusKm / (111.0 * Math.max(cosLat, 0.001));

      const minLat = latitude - latDelta;
      const maxLat = latitude + latDelta;
      const minLng = longitude - lngDelta;
      const maxLng = longitude + lngDelta;

      // Haversine formula SQL in km
      const distanceSql = `
        (6371 * acos(
          LEAST(1.0, GREATEST(-1.0, 
            cos(radians(${latitude})) * cos(radians(latitude)) *
            cos(radians(longitude) - radians(${longitude})) +
            sin(radians(${latitude})) * sin(radians(latitude))
          ))
        ))
      `;

      let query = db<ICourtRow>('courts')
        .select('courts.*')
        .select(db.raw(`${distanceSql} as distance_km`))
        .select(
          db.raw(
            '(SELECT COUNT(*)::int FROM court_reviews WHERE court_reviews.court_id = courts.id AND court_reviews.is_liked = true) as likes_count'
          )
        )
        .select(
          db.raw(
            '(SELECT COUNT(*)::int FROM court_reviews WHERE court_reviews.court_id = courts.id AND court_reviews.is_liked = false) as dislikes_count'
          )
        );

      if (userId) {
        query = query.select(
          db.raw(
            `(SELECT is_liked FROM court_reviews WHERE court_reviews.court_id = courts.id AND court_reviews.user_id = ?) as user_vote`,
            [userId]
          )
        );
      }

      if (!search || search.trim().length === 0) {
        query = query
          .whereBetween('latitude', [minLat, maxLat])
          .whereBetween('longitude', [minLng, maxLng]);
      }

      if (sport && sport.toLowerCase() !== 'all') {
        const normalizedSport = sport.toLowerCase().trim();
        query = query.whereRaw('LOWER(sports::text) LIKE ?', [`%${normalizedSport}%`]);
      }

      if (search && search.trim().length > 0) {
        const term = `%${search.trim().toLowerCase()}%`;
        query = query.where((builder) => {
          builder
            .whereRaw('LOWER(name) LIKE ?', [term])
            .orWhereRaw('LOWER(COALESCE(address, \'\')) LIKE ?', [term])
            .orWhereRaw('LOWER(COALESCE(city, \'\')) LIKE ?', [term]);
        });
      }

      const rows = await query
        .orderBy('distance_km', 'asc')
        .limit(limit);

      return rows.map(this.normalizeRow);
    } catch (err) {
      console.error('[CourtRepository findNearby Error]:', err);
      throw err;
    }
  }

  async findById(id: string, userId?: string): Promise<ICourtRow | undefined> {
    try {
      if (!this.isValidUuid(id)) {
        return undefined;
      }

      let query = db<ICourtRow>('courts')
        .select('courts.*')
        .select(
          db.raw(
            '(SELECT COUNT(*)::int FROM court_reviews WHERE court_reviews.court_id = courts.id AND court_reviews.is_liked = true) as likes_count'
          )
        )
        .select(
          db.raw(
            '(SELECT COUNT(*)::int FROM court_reviews WHERE court_reviews.court_id = courts.id AND court_reviews.is_liked = false) as dislikes_count'
          )
        )
        .where('courts.id', id)
        .first();

      if (userId) {
        query = query.select(
          db.raw(
            `(SELECT is_liked FROM court_reviews WHERE court_reviews.court_id = courts.id AND court_reviews.user_id = ?) as user_vote`,
            [userId]
          )
        );
      }

      const row = await query;
      return row ? this.normalizeRow(row) : undefined;
    } catch (err) {
      console.error('[CourtRepository findById Error]:', err);
      throw err;
    }
  }

  async findByOsmId(osmId: string): Promise<ICourtRow | undefined> {
    try {
      const row = await db<ICourtRow>('courts').where({ osm_id: osmId }).first();
      return row ? this.normalizeRow(row) : undefined;
    } catch (err) {
      console.error('[CourtRepository findByOsmId Error]:', err);
      throw err;
    }
  }

  async countInBoundingBox(lat: number, lng: number, radiusKm: number): Promise<number> {
    try {
      const latDelta = radiusKm / 111.0;
      const minLat = lat - latDelta;
      const maxLat = lat + latDelta;
      const minLng = lng - latDelta;
      const maxLng = lng + latDelta;

      const result = await db('courts')
        .whereBetween('latitude', [minLat, maxLat])
        .whereBetween('longitude', [minLng, maxLng])
        .count('id as total')
        .first();

      return Number(result?.total || 0);
    } catch (err) {
      console.error('[CourtRepository countInBoundingBox Error]:', err);
      return 0;
    }
  }

  async createCourt(payload: ICreateCourtPayload): Promise<ICourtRow> {
    try {
      const sportsJson = typeof payload.sports === 'string' 
        ? payload.sports 
        : JSON.stringify(payload.sports || ['pickleball']);

      let createdBy: string | null = payload.created_by || null;
      if (createdBy) {
        const userExists = await db('users').where({ id: createdBy }).select('id').first();
        if (!userExists) {
          createdBy = null;
        }
      }

      const [row] = await db<ICourtRow>('courts')
        .insert({
          osm_id: payload.osm_id || null,
          name: payload.name,
          address: payload.address || null,
          city: payload.city || null,
          latitude: payload.latitude,
          longitude: payload.longitude,
          sports: sportsJson,
          surface: payload.surface || null,
          has_lighting: payload.has_lighting ?? false,
          is_indoor: payload.is_indoor ?? false,
          access_type: payload.access_type || 'public',
          is_verified: payload.is_verified ?? true,
          created_by: createdBy,
          image_url: payload.image_url || null,
        })
        .returning('*');

      return this.normalizeRow(row);
    } catch (err) {
      console.error('[CourtRepository createCourt Error]:', err);
      throw err;
    }
  }

  async upsertFromOsm(payload: ICreateCourtPayload): Promise<ICourtRow> {
    try {
      if (!payload.osm_id) {
        return this.createCourt(payload);
      }

      const existing = await this.findByOsmId(payload.osm_id);
      const sportsJson = typeof payload.sports === 'string'
        ? payload.sports
        : JSON.stringify(payload.sports || ['pickleball']);

      if (existing) {
        const [updated] = await db<ICourtRow>('courts')
          .where({ id: existing.id })
          .update({
            name: payload.name,
            address: payload.address || existing.address,
            city: payload.city || existing.city,
            latitude: payload.latitude,
            longitude: payload.longitude,
            sports: sportsJson,
            surface: payload.surface || existing.surface,
            has_lighting: payload.has_lighting ?? existing.has_lighting,
            is_indoor: payload.is_indoor ?? existing.is_indoor,
            image_url: payload.image_url || existing.image_url,
            updated_at: new Date(),
          })
          .returning('*');
        return this.normalizeRow(updated);
      }

      return this.createCourt(payload);
    } catch (err) {
      console.error('[CourtRepository upsertFromOsm Error]:', err);
      throw err;
    }
  }

  // --- Ratings, Votes & Comments ---

  private isValidUuid(id: string): boolean {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
  }

  async upsertVote(
    courtId: string,
    userId: string,
    isLiked: boolean,
    trx?: Knex.Transaction
  ): Promise<ICourtReviewRow> {
    try {
      if (!this.isValidUuid(courtId)) {
        throw new Error(`Invalid court ID: ${courtId}`);
      }

      const runner = trx || db;

      const existing = await runner<ICourtReviewRow>('court_reviews')
        .where({ court_id: courtId, user_id: userId })
        .first();

      let recordId: string;
      if (existing) {
        const [updated] = await runner<ICourtReviewRow>('court_reviews')
          .where({ id: existing.id })
          .update({
            is_liked: isLiked,
            updated_at: new Date(),
          })
          .returning('*');
        recordId = updated.id;
      } else {
        const [created] = await runner<ICourtReviewRow>('court_reviews')
          .insert({
            court_id: courtId,
            user_id: userId,
            is_liked: isLiked,
          })
          .returning('*');
        recordId = created.id;
      }

      const voteWithUser = await runner('court_reviews')
        .leftJoin('users', 'court_reviews.user_id', 'users.id')
        .select(
          'court_reviews.*',
          'users.name as user_name',
          'users.avatar_url as user_avatar'
        )
        .where('court_reviews.id', recordId)
        .first();

      return voteWithUser;
    } catch (err) {
      console.error('[CourtRepository upsertVote Error]:', err);
      throw err;
    }
  }

  async createComment(
    courtId: string,
    userId: string,
    comment: string,
    trx?: Knex.Transaction
  ): Promise<ICourtCommentRow> {
    try {
      if (!this.isValidUuid(courtId)) {
        throw new Error(`Invalid court ID: ${courtId}`);
      }

      const runner = trx || db;

      const [created] = await runner<ICourtCommentRow>('court_comments')
        .insert({
          court_id: courtId,
          user_id: userId,
          comment: comment.trim(),
        })
        .returning('*');

      const commentWithUser = await runner('court_comments')
        .leftJoin('users', 'court_comments.user_id', 'users.id')
        .select(
          'court_comments.*',
          'users.name as user_name',
          'users.avatar_url as user_avatar'
        )
        .where('court_comments.id', created.id)
        .first();

      return commentWithUser;
    } catch (err) {
      console.error('[CourtRepository createComment Error]:', err);
      throw err;
    }
  }

  async getCourtComments(courtId: string): Promise<ICourtCommentRow[]> {
    try {
      if (!this.isValidUuid(courtId)) {
        return [];
      }

      const rows = await db('court_comments')
        .leftJoin('users', 'court_comments.user_id', 'users.id')
        .select(
          'court_comments.*',
          'users.name as user_name',
          'users.avatar_url as user_avatar'
        )
        .where('court_comments.court_id', courtId)
        .orderBy('court_comments.created_at', 'desc')
        .limit(100);

      return rows;
    } catch (err) {
      console.error('[CourtRepository getCourtComments Error]:', err);
      throw err;
    }
  }

  async upsertReview(courtId: string, userId: string, isLiked?: boolean, comment?: string | null): Promise<any> {
    try {
      if (!this.isValidUuid(courtId)) {
        throw new Error(`Invalid court ID: ${courtId}`);
      }

      return await db.transaction(async (trx) => {
        let voteRecord: ICourtReviewRow | undefined;
        if (typeof isLiked === 'boolean') {
          voteRecord = await this.upsertVote(courtId, userId, isLiked, trx);
        }

        let commentRecord: ICourtCommentRow | undefined;
        if (comment && comment.trim().length > 0) {
          commentRecord = await this.createComment(courtId, userId, comment.trim(), trx);
        }

        if (commentRecord) {
          return {
            ...commentRecord,
            is_liked: voteRecord ? voteRecord.is_liked : (typeof isLiked === 'boolean' ? isLiked : true),
          };
        }

        return voteRecord;
      });
    } catch (err) {
      console.error('[CourtRepository upsertReview Error]:', err);
      throw err;
    }
  }

  async getCourtReviews(courtId: string): Promise<ICourtReviewRow[]> {
    try {
      if (!this.isValidUuid(courtId)) {
        return [];
      }

      const rows = await db('court_reviews')
        .leftJoin('users', 'court_reviews.user_id', 'users.id')
        .select(
          'court_reviews.*',
          'users.name as user_name',
          'users.avatar_url as user_avatar'
        )
        .where('court_reviews.court_id', courtId)
        .orderBy('court_reviews.created_at', 'desc')
        .limit(100);

      return rows;
    } catch (err) {
      console.error('[CourtRepository getCourtReviews Error]:', err);
      throw err;
    }
  }

  async deleteReview(courtId: string, userId: string): Promise<boolean> {
    try {
      if (!this.isValidUuid(courtId)) {
        return false;
      }

      const deletedVotes = await db('court_reviews')
        .where({ court_id: courtId, user_id: userId })
        .delete();
      const deletedComments = await db('court_comments')
        .where({ court_id: courtId, user_id: userId })
        .delete();
      return deletedVotes > 0 || deletedComments > 0;
    } catch (err) {
      console.error('[CourtRepository deleteReview Error]:', err);
      throw err;
    }
  }

  async deleteComment(commentId: string, userId: string): Promise<boolean> {
    try {
      if (!this.isValidUuid(commentId)) {
        return false;
      }

      const deleted = await db('court_comments')
        .where({ id: commentId, user_id: userId })
        .delete();
      return deleted > 0;
    } catch (err) {
      console.error('[CourtRepository deleteComment Error]:', err);
      throw err;
    }
  }

  private normalizeRow(row: ICourtRow): ICourtRow {
    let parsedSports: string[] = [];
    if (typeof row.sports === 'string') {
      try {
        parsedSports = JSON.parse(row.sports);
      } catch {
        parsedSports = [row.sports];
      }
    } else if (Array.isArray(row.sports)) {
      parsedSports = row.sports;
    }

    return {
      ...row,
      sports: parsedSports,
      distance_km: row.distance_km != null ? Number(Number(row.distance_km).toFixed(2)) : undefined,
      likes_count: row.likes_count != null ? Number(row.likes_count) : 0,
      dislikes_count: row.dislikes_count != null ? Number(row.dislikes_count) : 0,
    };
  }
}

export default new CourtRepository();
