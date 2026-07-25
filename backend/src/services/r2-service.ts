import '../config/crypto-polyfill';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import crypto from 'crypto';

export class R2Service {
  private s3Client: S3Client | null = null;
  private bucketName: string;
  private accountId: string;
  private publicDomain: string;

  constructor() {
    this.accountId = process.env.R2_ACCOUNT_ID || '';
    this.bucketName = process.env.R2_BUCKET_NAME || 'pulse-avatars';
    this.publicDomain = process.env.R2_PUBLIC_DOMAIN || '';

    const accessKeyId = process.env.R2_ACCESS_KEY_ID || '';
    const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY || '';

    if (this.accountId && accessKeyId && secretAccessKey) {
      this.s3Client = new S3Client({
        region: 'auto',
        endpoint: `https://${this.accountId}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId,
          secretAccessKey,
        },
        forcePathStyle: true,
        requestChecksumCalculation: 'WHEN_REQUIRED',
        responseChecksumValidation: 'WHEN_REQUIRED',
      });
    }
  }

  /**
   * Check if Cloudflare R2 is fully configured in environment
   */
  public isConfigured(): boolean {
    return this.s3Client !== null;
  }

  /**
   * Generate a Presigned Upload URL for direct client-to-R2 upload
   */
  public async getPresignedUploadUrl(userId: string, contentType: string = 'image/jpeg'): Promise<{ uploadUrl: string; avatarUrl: string; key: string }> {
    const ext = contentType.split('/')[1] || 'jpg';
    const randomHash = crypto.randomBytes(8).toString('hex');
    const key = `avatars/user_${userId}_${randomHash}.${ext}`;

    if (!this.s3Client) {
      // Fallback response for dev mode when R2 credentials aren't set yet
      const baseUrl = process.env.BASE_URL || 'http://localhost:5000';
      return {
        uploadUrl: `${baseUrl}/api/v1/upload/local/${key}`,
        avatarUrl: `${baseUrl}/uploads/${key}`,
        key,
      };
    }

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3Client, command, { expiresIn: 900 });

    let avatarUrl: string;
    if (this.publicDomain) {
      const cleanDomain = this.publicDomain.replace(/^https?:\/\//, '').replace(/\/$/, '');
      avatarUrl = `https://${cleanDomain}/${key}`;
    } else {
      avatarUrl = `https://pub-${this.accountId}.r2.dev/${key}`;
    }

    return {
      uploadUrl,
      avatarUrl,
      key,
    };
  }
}

export default new R2Service();
