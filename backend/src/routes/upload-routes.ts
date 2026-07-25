import { Router } from 'express';
import UploadController from '../controllers/upload-controller';
import { authenticateToken } from '../middleware/auth-middleware';

const router = Router();
const uploadController = new UploadController();

// Protected endpoint to request presigned upload URL for Cloudflare R2
router.post('/presigned-url', authenticateToken, uploadController.getPresignedUrl);

export default router;
