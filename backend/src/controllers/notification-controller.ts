import type { Response } from 'express';
import type { AuthenticatedRequest } from '../middleware/auth-middleware';
import notificationService from '../services/notification-service';

class NotificationController {
  getUserNotifications = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const unreadOnly = req.query.unread === 'true';
      const notifications = await notificationService.getUserNotifications(userId, unreadOnly);

      res.status(200).json({
        message: 'Notifications retrieved successfully',
        data: notifications,
      });
    } catch (error: any) {
      res.status(500).json({ error: error.message || 'Failed to fetch notifications' });
    }
  };

  markAsRead = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      const { id } = req.params;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const success = await notificationService.markAsRead(id, userId);

      res.status(200).json({
        message: success ? 'Notification marked as read' : 'Notification not found',
        data: { success },
      });
    } catch (error: any) {
      res.status(500).json({ error: error.message || 'Failed to mark notification as read' });
    }
  };

  markAllAsRead = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const count = await notificationService.markAllAsRead(userId);

      res.status(200).json({
        message: 'All notifications marked as read',
        data: { count },
      });
    } catch (error: any) {
      res.status(500).json({ error: error.message || 'Failed to mark all notifications as read' });
    }
  };
}

export default new NotificationController();
