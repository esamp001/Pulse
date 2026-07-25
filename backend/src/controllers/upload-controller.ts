import type { Response } from 'express';
import { z } from 'zod';
import r2Service from '../services/r2-service';
import type { AuthenticatedRequest } from '../middleware/auth-middleware';

const presignedUrlSchema = z.object({
  contentType: z.string().default('image/jpeg'),
});

class UploadController {
  /**
   * Get a presigned upload URL for Cloudflare R2
   */
  getPresignedUrl = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId || 'guest';
      const validation = presignedUrlSchema.safeParse(req.body);

      const contentType = validation.success ? validation.data.contentType : 'image/jpeg';

      const result = await r2Service.getPresignedUploadUrl(userId, contentType);

      res.status(200).json({
        message: 'Presigned upload URL generated successfully',
        data: {
          uploadUrl: result.uploadUrl,
          avatarUrl: result.avatarUrl,
          key: result.key,
          isR2Configured: r2Service.isConfigured(),
        },
      });
    } catch (error: any) {
      res.status(500).json({ error: error.message || 'Failed to generate upload URL' });
    }
  };
}

export default UploadController;
