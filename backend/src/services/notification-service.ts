import notificationRepository, { INotificationRow } from '../repositories/notification-repository';

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
    return notificationRepository.createNotification(data);
  }
}

export default new NotificationService();
