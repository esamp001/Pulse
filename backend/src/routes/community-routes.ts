import { Router } from 'express';
import { optionalAuthenticateToken } from '../middleware/auth-middleware';
import communityWaitlistController from '../controllers/community-waitlist-controller';

const router = Router();

router.post('/waitlist/subscribe', optionalAuthenticateToken, communityWaitlistController.subscribe);
router.post('/waitlist/unsubscribe', optionalAuthenticateToken, communityWaitlistController.unsubscribe);
router.get('/waitlist/status', optionalAuthenticateToken, communityWaitlistController.getStatus);

export default router;
