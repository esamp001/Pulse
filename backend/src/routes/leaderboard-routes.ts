import { Router } from 'express';
import { LeaderboardController } from '../controllers/leaderboard-controller';
import { optionalAuthenticateToken } from '../middleware/auth-middleware';

const router = Router();
const leaderboardController = new LeaderboardController();

router.get('/', optionalAuthenticateToken, leaderboardController.getLeaderboard);

export default router;
