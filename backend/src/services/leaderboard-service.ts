import { LeaderboardRepository } from '../repositories/leaderboard-repository';
import type { GetLeaderboardOptions, LeaderboardResponse } from '../types/leaderboard';

export class LeaderboardService {
  private leaderboardRepository = new LeaderboardRepository();

  async getLeaderboard(options: GetLeaderboardOptions): Promise<LeaderboardResponse> {
    const validCategories = ['elo', 'win_rate', 'matches'];
    const category = validCategories.includes(options.category) ? options.category : 'elo';
    const sport = (options.sport || 'all').toLowerCase().trim();
    const limit = Math.min(Math.max(1, Number(options.limit) || 50), 100);
    const offset = Math.max(0, Number(options.offset) || 0);

    const { entries, currentUserEntry } = await this.leaderboardRepository.getLeaderboard({
      sport,
      category,
      limit,
      offset,
      currentUserId: options.currentUserId,
    });

    return {
      entries,
      currentUserEntry: currentUserEntry || null,
      sport,
      category,
      hasMore: entries.length === limit,
      limit,
      offset,
    };
  }
}
