import type { Request, Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth-middleware';
import db from '../database/db';
import courtService from '../services/court-service';

export class CourtController {
  /**
   * GET /api/v1/courts
   * Query nearby courts with distance, sport filtering, and search
   */
  async getCourts(req: Request, res: Response): Promise<void> {
    try {
      // Default to Metro Manila center if coordinates not supplied
      const lat = req.query.lat ? parseFloat(req.query.lat as string) : 14.5995;
      const lng = req.query.lng ? parseFloat(req.query.lng as string) : 120.9842;
      const radiusKm = req.query.radius ? parseFloat(req.query.radius as string) : 25;
      const sport = req.query.sport as string | undefined;
      const search = req.query.search as string | undefined;

      if (isNaN(lat) || isNaN(lng)) {
        res.status(400).json({ error: 'Invalid latitude or longitude parameters' });
        return;
      }

      const courts = await courtService.getNearbyCourts({
        latitude: lat,
        longitude: lng,
        radiusKm,
        sport,
        search,
      });

      res.status(200).json({
        success: true,
        message: 'Courts fetched successfully',
        count: courts.length,
        data: courts,
      });
    } catch (err: any) {
      console.error('[CourtController getCourts Error]:', err);
      res.status(500).json({ error: err.message || 'Failed to fetch courts' });
    }
  }

  /**
   * POST /api/v1/courts/sync
   * Trigger on-demand sync with OpenStreetMap Overpass API
   */
  async syncOsm(req: Request, res: Response): Promise<void> {
    try {
      const lat = req.body.lat ? parseFloat(req.body.lat) : 14.5995;
      const lng = req.body.lng ? parseFloat(req.body.lng) : 120.9842;
      const radiusKm = req.body.radiusKm ? parseFloat(req.body.radiusKm) : 15;
      const sport = req.body.sport as string | undefined;

      const syncedCount = await courtService.syncFromOpenStreetMap(lat, lng, radiusKm, sport);

      res.status(200).json({
        success: true,
        message: `Synced ${syncedCount} courts from OpenStreetMap`,
        syncedCount,
      });
    } catch (err: any) {
      console.error('[CourtController syncOsm Error]:', err);
      res.status(500).json({ error: err.message || 'Failed to sync courts from OpenStreetMap' });
    }
  }

  /**
   * POST /api/v1/courts
   * Suggest or add a local court
   */
  async createCourt(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      let userId = req.user?.userId || null;
      
      if (userId) {
        const userExists = await db('users').where({ id: userId }).select('id').first();
        if (!userExists) {
          userId = null;
        }
      }

      const {
        name,
        address,
        city,
        latitude,
        longitude,
        sports,
        surface,
        has_lighting,
        is_indoor,
        access_type,
        image_url,
      } = req.body;

      if (!name || typeof name !== 'string') {
        res.status(400).json({ error: 'Court name is required' });
        return;
      }

      if (latitude == null || longitude == null || isNaN(latitude) || isNaN(longitude)) {
        res.status(400).json({ error: 'Valid latitude and longitude are required' });
        return;
      }

      const court = await courtService.createCourt(userId, {
        name: name.trim(),
        address: address?.trim(),
        city: city?.trim(),
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        sports: Array.isArray(sports) && sports.length > 0 ? sports : ['pickleball'],
        surface: surface?.trim(),
        has_lighting: Boolean(has_lighting),
        is_indoor: Boolean(is_indoor),
        access_type: access_type || 'public',
        image_url: typeof image_url === 'string' && image_url.trim().length > 0 ? image_url.trim() : undefined,
      });

      res.status(201).json({
        success: true,
        message: 'Court added successfully',
        data: court,
      });
    } catch (err: any) {
      console.error('[CourtController createCourt Error]:', err);
      res.status(500).json({ error: err.message || 'Failed to create court' });
    }
  }

  /**
   * GET /api/v1/courts/:id/reviews
   * Fetch court reviews and rating breakdown
   */
  async getReviews(req: Request, res: Response): Promise<void> {
    try {
      const courtId = req.params.id;
      if (!courtId) {
        res.status(400).json({ error: 'Court ID is required' });
        return;
      }

      const userId = (req as AuthenticatedRequest).user?.userId;
      const reviewsData = await courtService.getCourtReviews(courtId, userId);
      res.status(200).json({
        success: true,
        data: reviewsData,
      });
    } catch (err: any) {
      console.error('[CourtController getReviews Error]:', err);
      res.status(500).json({ error: err.message || 'Failed to fetch reviews' });
    }
  }

  /**
   * POST /api/v1/courts/:id/reviews
   * Submit or update a like/dislike review
   */
  async submitReview(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const courtId = req.params.id;
      const userId = req.user?.userId;

      if (!userId) {
        res.status(401).json({ error: 'Authentication required to review court' });
        return;
      }

      const userExists = await db('users').where({ id: userId }).select('id').first();
      if (!userExists) {
        res.status(401).json({ error: 'User account not found' });
        return;
      }

      const { is_liked, comment } = req.body;
      const hasLiked = typeof is_liked === 'boolean';
      const hasComment = typeof comment === 'string' && comment.trim().length > 0;

      if (!hasLiked && !hasComment) {
        res.status(400).json({ error: 'Either is_liked (boolean) or comment (string) is required' });
        return;
      }

      const review = await courtService.submitReview(
        courtId,
        userId!,
        hasLiked ? is_liked : undefined,
        hasComment ? comment : null
      );

      res.status(200).json({
        success: true,
        message: 'Review submitted successfully',
        data: review,
      });
    } catch (err: any) {
      console.error('[CourtController submitReview Error]:', err);
      res.status(500).json({ error: err.message || 'Failed to submit review' });
    }
  }

  /**
   * DELETE /api/v1/courts/:id/reviews
   * Delete user review
   */
  async deleteReview(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const courtId = req.params.id;
      const userId = req.user?.userId;

      if (!userId) {
        res.status(401).json({ error: 'Authentication required' });
        return;
      }

      await courtService.deleteReview(courtId, userId);
      res.status(200).json({
        success: true,
        message: 'Review deleted successfully',
      });
    } catch (err: any) {
      console.error('[CourtController deleteReview Error]:', err);
      res.status(500).json({ error: err.message || 'Failed to delete review' });
    }
  }
}

export default new CourtController();
