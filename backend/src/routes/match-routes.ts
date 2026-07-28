import { Router } from 'express';
import MatchController from '../controllers/match-controller';
import { authenticateToken } from '../middleware/auth-middleware';

const router = Router();
const matchController = new MatchController();

router.post('/', authenticateToken, matchController.createMatch);
router.get('/', authenticateToken, matchController.getUserMatches);
router.get('/active', authenticateToken, matchController.getActiveMatch);
router.get('/users/search', authenticateToken, matchController.searchUsers);
router.get('/:id', authenticateToken, matchController.getMatchById);
router.patch('/:id/participants', authenticateToken, matchController.assignParticipant);
router.delete('/:id/exit', authenticateToken, matchController.exitMatch);

export default router;
