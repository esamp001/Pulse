import db from '../database/db';

export interface INotificationRow {
  id: string;
  user_id: string;
  category: string;
  title: string;
  subtitle: string;
  is_read: boolean;
  payload?: any;
  created_at: Date;
  updated_at: Date;
}

class NotificationRepository {
  async createNotification(data: {
    userId: string;
    category: string;
    title: string;
    subtitle: string;
    payload?: any;
  }): Promise<INotificationRow> {
    const [row] = await db<INotificationRow>('notifications')
      .insert({
        user_id: data.userId,
        category: data.category,
        title: data.title,
        subtitle: data.subtitle,
        payload: data.payload ? data.payload : null,
      })
      .returning('*');
    return row;
  }

  async getNotificationsByUserId(userId: string, unreadOnly = false): Promise<INotificationRow[]> {
    let query = db<INotificationRow>('notifications')
      .where({ user_id: userId });

    if (unreadOnly) {
      query = query.where({ is_read: false });
    }

    return query.orderBy('created_at', 'desc').limit(50);
  }

  async markAsRead(id: string, userId: string): Promise<boolean> {
    const updatedCount = await db<INotificationRow>('notifications')
      .where({ id, user_id: userId })
      .update({ is_read: true, updated_at: new Date() });
    return updatedCount > 0;
  }

  async markAllAsRead(userId: string): Promise<number> {
    return db<INotificationRow>('notifications')
      .where({ user_id: userId, is_read: false })
      .update({ is_read: true, updated_at: new Date() });
  }
}

export default new NotificationRepository();
