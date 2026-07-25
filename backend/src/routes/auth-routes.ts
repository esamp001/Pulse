import { Router } from 'express';
import AuthController from '../controllers/auth-controller';
import { authenticateToken } from '../middleware/auth-middleware';

const router = Router();
const authController = new AuthController();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/google', authController.googleAuth);
router.get('/me', authenticateToken, authController.getMe);
router.patch('/onboard', authenticateToken, authController.onboard);

export default router;
