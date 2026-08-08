import db from '../database/db';

export interface ICommunityWaitlistRow {
  id: string;
  user_id: string | null;
  email: string;
  feature: string;
  created_at: Date;
  updated_at: Date;
}

class CommunityWaitlistRepository {
  async subscribe(
    userId: string | null,
    email: string,
    feature: string = 'community'
  ): Promise<ICommunityWaitlistRow> {
    try {
      if (userId) {
        const existing = await db<ICommunityWaitlistRow>('community_waitlist')
          .where({ user_id: userId, feature })
          .first();

        if (existing) {
          const [updated] = await db<ICommunityWaitlistRow>('community_waitlist')
            .where({ id: existing.id })
            .update({ email, updated_at: new Date() })
            .returning('*');
          return updated;
        }
      } else {
        const existing = await db<ICommunityWaitlistRow>('community_waitlist')
          .where({ email, feature })
          .first();

        if (existing) {
          const [updated] = await db<ICommunityWaitlistRow>('community_waitlist')
            .where({ id: existing.id })
            .update({ updated_at: new Date() })
            .returning('*');
          return updated;
        }
      }

      const [inserted] = await db<ICommunityWaitlistRow>('community_waitlist')
        .insert({
          user_id: userId,
          email,
          feature,
        })
        .returning('*');

      return inserted;
    } catch (err) {
      console.error('[CommunityWaitlistRepository Subscribe Error]:', err);
      throw err;
    }
  }

  async unsubscribe(
    userId: string | null,
    email?: string,
    feature: string = 'community'
  ): Promise<boolean> {
    try {
      let query = db<ICommunityWaitlistRow>('community_waitlist').where({ feature });

      if (userId) {
        query = query.where({ user_id: userId });
      } else if (email) {
        query = query.where({ email });
      } else {
        return false;
      }

      const deletedCount = await query.delete();
      return deletedCount > 0;
    } catch (err) {
      console.error('[CommunityWaitlistRepository Unsubscribe Error]:', err);
      throw err;
    }
  }

  async findSubscription(
    userId: string | null,
    email?: string,
    feature: string = 'community'
  ): Promise<ICommunityWaitlistRow | undefined> {
    try {
      let query = db<ICommunityWaitlistRow>('community_waitlist').where({ feature });

      if (userId) {
        query = query.where({ user_id: userId });
      } else if (email) {
        query = query.where({ email });
      } else {
        return undefined;
      }

      return await query.first();
    } catch (err) {
      console.error('[CommunityWaitlistRepository FindSubscription Error]:', err);
      throw err;
    }
  }
}

export default new CommunityWaitlistRepository();
