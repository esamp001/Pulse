import type { Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth-middleware';
import communityWaitlistService from '../services/community-waitlist-service';

class CommunityWaitlistController {
  subscribe = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId || null;
      const { email, feature = 'community' } = req.body || {};

      const result = await communityWaitlistService.subscribe(userId, email, feature);

      res.status(200).json({
        message: 'Successfully subscribed to feature waitlist.',
        data: result,
      });
    } catch (error: any) {
      console.error('[CommunityWaitlistController Subscribe Error]:', error);
      res.status(400).json({ error: error.message || 'Failed to join waitlist' });
    }
  };

  unsubscribe = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId || null;
      const { email, feature = 'community' } = req.body || {};

      const result = await communityWaitlistService.unsubscribe(userId, email, feature);

      res.status(200).json({
        message: 'Successfully unsubscribed from feature waitlist.',
        data: result,
      });
    } catch (error: any) {
      console.error('[CommunityWaitlistController Unsubscribe Error]:', error);
      res.status(400).json({ error: error.message || 'Failed to unsubscribe from waitlist' });
    }
  };

  getStatus = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId || null;
      const email = typeof req.query.email === 'string' ? req.query.email : undefined;
      const feature = typeof req.query.feature === 'string' ? req.query.feature : 'community';

      const result = await communityWaitlistService.getStatus(userId, email, feature);

      res.status(200).json({
        message: 'Waitlist status retrieved successfully.',
        data: result,
      });
    } catch (error: any) {
      console.error('[CommunityWaitlistController GetStatus Error]:', error);
      res.status(500).json({ error: error.message || 'Failed to retrieve waitlist status' });
    }
  };
}

export default new CommunityWaitlistController();
