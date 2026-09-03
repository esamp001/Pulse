import { Router } from 'express';
import courtController from '../controllers/court-controller';
import { authenticateToken, optionalAuthenticateToken } from '../middleware/auth-middleware';

const router = Router();

// GET /api/v1/courts (List & search nearby courts)
router.get('/', optionalAuthenticateToken, (req, res) => courtController.getCourts(req, res));

// POST /api/v1/courts/sync (Force on-demand OSM sync)
router.post('/sync', optionalAuthenticateToken, (req, res) => courtController.syncOsm(req, res));

// POST /api/v1/courts (Suggest or add a local court)
router.post('/', optionalAuthenticateToken, (req, res) => courtController.createCourt(req, res));

// GET /api/v1/courts/:id/reviews (Get court reviews & ratings)
router.get('/:id/reviews', optionalAuthenticateToken, (req, res) => courtController.getReviews(req, res));

// POST /api/v1/courts/:id/reviews (Submit or update like/dislike & comment)
router.post('/:id/reviews', authenticateToken, (req, res) => courtController.submitReview(req, res));

// DELETE /api/v1/courts/:id/reviews (Delete user review)
router.delete('/:id/reviews', authenticateToken, (req, res) => courtController.deleteReview(req, res));

export default router;
