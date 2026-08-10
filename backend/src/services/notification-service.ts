import notificationRepository, { INotificationRow } from '../repositories/notification-repository';
import fcmService from './fcm-service';

class NotificationService {
  async getUserNotifications(userId: string, unreadOnly = false): Promise<INotificationRow[]> {
    return notificationRepository.getNotificationsByUserId(userId, unreadOnly);
  }

  async markAsRead(id: string, userId: string): Promise<boolean> {
    return notificationRepository.markAsRead(id, userId);
  }

  async markAllAsRead(userId: string): Promise<number> {
    return notificationRepository.markAllAsRead(userId);
  }

  async createNotification(data: {
    userId: string;
    category: 'ACCOUNT' | 'INVITE' | 'RATING' | 'VERIFIED';
    title: string;
    subtitle: string;
    payload?: any;
  }): Promise<INotificationRow> {
    const notification = await notificationRepository.createNotification(data);
    
    // Asynchronously trigger FCM Push Notification to recipient's device token
    fcmService.sendPushNotification(data.userId, data.title, data.subtitle, {
      category: data.category,
      notificationId: notification.id,
      ...(data.payload || {}),
    }).catch((err) => {
      console.error('[NotificationService Error]: FCM Push Notification trigger failed', err);
    });

    return notification;
  }
}

export default new NotificationService();
