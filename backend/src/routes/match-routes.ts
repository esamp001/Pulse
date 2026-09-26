import { Router } from 'express';
import MatchController from '../controllers/match-controller';
import { authenticateToken } from '../middleware/auth-middleware';

const router = Router();
const matchController = new MatchController();

router.post('/', authenticateToken, matchController.createMatch);
router.get('/', authenticateToken, matchController.getUserMatches);
router.get('/active', authenticateToken, matchController.getActiveMatch);
router.get('/open', authenticateToken, matchController.getOpenMatches);
router.post('/join-by-pin', authenticateToken, matchController.joinMatchByPin);
router.post('/:id/join-open', authenticateToken, matchController.joinOpenMatch);
router.get('/users/search', authenticateToken, matchController.searchUsers);
router.get('/:id', authenticateToken, matchController.getMatchById);
router.patch('/:id/participants', authenticateToken, matchController.assignParticipant);
router.patch('/:id/switch-role', authenticateToken, matchController.switchRole);
router.patch('/:id/accept', authenticateToken, matchController.acceptInvitation);
router.patch('/:id/decline', authenticateToken, matchController.declineInvitation);
router.patch('/:id/status', authenticateToken, matchController.updateStatus);
router.patch('/:id/finalize', authenticateToken, matchController.finalizeMatch);
router.post('/:id/finalize', authenticateToken, matchController.finalizeMatch);
router.post('/:id/complete', authenticateToken, matchController.finalizeMatch);
router.delete('/:id/participants/:role', authenticateToken, matchController.kickParticipant);
router.delete('/:id/exit', authenticateToken, matchController.exitMatch);

export default router;

