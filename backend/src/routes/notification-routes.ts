import { Router } from 'express';
import { authenticateToken } from '../middleware/auth-middleware';
import notificationController from '../controllers/notification-controller';

const router = Router();

router.use(authenticateToken);

router.get('/', notificationController.getUserNotifications);
router.patch('/read-all', notificationController.markAllAsRead);
router.patch('/:id/read', notificationController.markAsRead);

export default router;
