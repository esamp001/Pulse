import communityWaitlistRepository from '../repositories/community-waitlist-repository';
import UserRepository from '../repositories/user-repository';

class CommunityWaitlistService {
  private userRepository = new UserRepository();

  async subscribe(userId: string | null, emailInput?: string, feature: string = 'community') {
    try {
      let email = emailInput;

      if (userId) {
        const user = await this.userRepository.findById(userId);
        if (user && user.email) {
          email = user.email;
        }
      }

      if (!email) {
        throw new Error('Email is required to join the waitlist.');
      }

      const record = await communityWaitlistRepository.subscribe(userId, email, feature);
      return {
        subscribed: true,
        record,
      };
    } catch (err) {
      console.error('[CommunityWaitlistService Subscribe Error]:', err);
      throw err;
    }
  }

  async unsubscribe(userId: string | null, emailInput?: string, feature: string = 'community') {
    try {
      let email = emailInput;
      if (userId && !email) {
        const user = await this.userRepository.findById(userId);
        if (user) email = user.email;
      }

      const success = await communityWaitlistRepository.unsubscribe(userId, email, feature);
      return {
        subscribed: false,
        success,
      };
    } catch (err) {
      console.error('[CommunityWaitlistService Unsubscribe Error]:', err);
      throw err;
    }
  }

  async getStatus(userId: string | null, emailInput?: string, feature: string = 'community') {
    try {
      let email = emailInput;
      if (userId && !email) {
        const user = await this.userRepository.findById(userId);
        if (user) email = user.email;
      }

      const subscription = await communityWaitlistRepository.findSubscription(userId, email, feature);
      return {
        isSubscribed: !!subscription,
        subscription: subscription || null,
      };
    } catch (err) {
      console.error('[CommunityWaitlistService GetStatus Error]:', err);
      throw err;
    }
  }
}

export default new CommunityWaitlistService();
