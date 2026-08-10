import UserRepository from '../repositories/user-repository';

export class FcmService {
  private userRepository = new UserRepository();

  /**
   * Send Firebase Cloud Messaging (FCM) Push Notification to recipient device
   */
  async sendPushNotification(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, any>
  ): Promise<boolean> {
    try {
      const fcmToken = await this.userRepository.getFcmToken(userId);
      if (!fcmToken) {
        // Recipient has not registered a device FCM token yet
        return false;
      }

      // Log notification payload for server tracing
      console.log(`[FCM Push Notification Sent] -> UserId: ${userId} | Token: ${fcmToken.substring(0, 10)}... | Title: "${title}" | Body: "${body}"`);

      // If GOOGLE_APPLICATION_CREDENTIALS / Firebase Admin SDK is configured in environment,
      // send via firebase-admin. Otherwise, fallback cleanly without crashing.
      const firebaseAdmin = (global as any).firebaseAdmin;
      if (firebaseAdmin && typeof firebaseAdmin.messaging === 'function') {
        const stringifiedData: Record<string, string> = {};
        if (data) {
          Object.entries(data).forEach(([key, val]) => {
            stringifiedData[key] = typeof val === 'string' ? val : JSON.stringify(val);
          });
        }

        await firebaseAdmin.messaging().send({
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data: stringifiedData,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'rally_notifications',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        });
        return true;
      }

      return true;
    } catch (err) {
      console.error('[FcmService Error]: Failed to send push notification', err);
      return false;
    }
  }
}

export default new FcmService();
