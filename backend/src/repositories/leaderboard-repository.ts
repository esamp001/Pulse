import db from '../database/db';
import type { GetLeaderboardOptions, LeaderboardEntry } from '../types/leaderboard';

export class LeaderboardRepository {
  async getLeaderboard(options: GetLeaderboardOptions): Promise<{ entries: LeaderboardEntry[]; currentUserEntry?: LeaderboardEntry | null }> {
    const { sport, category, limit = 50, offset = 0, currentUserId } = options;
    const cleanSport = (sport || 'all').toLowerCase().trim();

    let query = db('user_sport_stats')
      .join('users', 'users.id', 'user_sport_stats.user_id')
      .select(
        'users.id as id',
        'users.name as name',
        'users.avatar_url as avatar_url',
        'user_sport_stats.sport as sport',
        'user_sport_stats.rating as rating',
        'user_sport_stats.wins as wins',
        'user_sport_stats.losses as losses',
        db.raw('(user_sport_stats.wins + user_sport_stats.losses) as total_matches'),
        db.raw(`
          CASE 
            WHEN (user_sport_stats.wins + user_sport_stats.losses) > 0 
            THEN ROUND((user_sport_stats.wins::decimal / (user_sport_stats.wins + user_sport_stats.losses)) * 100, 1) 
            ELSE 0 
          END as win_rate
        `)
      );

    if (cleanSport !== 'all') {
      query = query.whereRaw('LOWER(user_sport_stats.sport) = ?', [cleanSport]);
    } else {
      query = query.where('user_sport_stats.is_primary', true);
    }

    switch (category) {
      case 'win_rate':
        query = query
          .orderByRaw('win_rate DESC')
          .orderBy('user_sport_stats.wins', 'desc')
          .orderBy('user_sport_stats.rating', 'desc');
        break;
      case 'matches':
        query = query
          .orderByRaw('(user_sport_stats.wins + user_sport_stats.losses) DESC')
          .orderBy('user_sport_stats.wins', 'desc')
          .orderBy('user_sport_stats.rating', 'desc');
        break;
      case 'elo':
      default:
        query = query
          .orderBy('user_sport_stats.rating', 'desc')
          .orderBy('user_sport_stats.wins', 'desc');
        break;
    }

    const rawRows = await query.limit(limit).offset(offset);

    const entries: LeaderboardEntry[] = rawRows.map((row: any, idx: number) => ({
      rank: offset + idx + 1,
      id: row.id,
      name: row.name || 'Anonymous Player',
      avatar_url: row.avatar_url || null,
      sport: row.sport,
      rating: Number(row.rating) || 1200,
      wins: Number(row.wins) || 0,
      losses: Number(row.losses) || 0,
      total_matches: Number(row.total_matches) || 0,
      win_rate: Number(row.win_rate) || 0,
      is_current_user: currentUserId ? row.id === currentUserId : false,
    }));

    let currentUserEntry: LeaderboardEntry | null = null;
    if (currentUserId) {
      const existingInPage = entries.find((e) => e.id === currentUserId);
      if (existingInPage) {
        currentUserEntry = existingInPage;
      } else {
        currentUserEntry = await this.getUserLeaderboardRank(currentUserId, cleanSport, category);
      }
    }

    return { entries, currentUserEntry };
  }

  async getUserLeaderboardRank(
    userId: string,
    cleanSport: string,
    category: 'elo' | 'win_rate' | 'matches'
  ): Promise<LeaderboardEntry | null> {
    let fullQuery = db('user_sport_stats')
      .join('users', 'users.id', 'user_sport_stats.user_id')
      .select(
        'users.id as id',
        'users.name as name',
        'users.avatar_url as avatar_url',
        'user_sport_stats.sport as sport',
        'user_sport_stats.rating as rating',
        'user_sport_stats.wins as wins',
        'user_sport_stats.losses as losses',
        db.raw('(user_sport_stats.wins + user_sport_stats.losses) as total_matches'),
        db.raw(`
          CASE 
            WHEN (user_sport_stats.wins + user_sport_stats.losses) > 0 
            THEN ROUND((user_sport_stats.wins::decimal / (user_sport_stats.wins + user_sport_stats.losses)) * 100, 1) 
            ELSE 0 
          END as win_rate
        `)
      );

    if (cleanSport !== 'all') {
      fullQuery = fullQuery.whereRaw('LOWER(user_sport_stats.sport) = ?', [cleanSport]);
    } else {
      fullQuery = fullQuery.where('user_sport_stats.is_primary', true);
    }

    switch (category) {
      case 'win_rate':
        fullQuery = fullQuery
          .orderByRaw('win_rate DESC')
          .orderBy('user_sport_stats.wins', 'desc')
          .orderBy('user_sport_stats.rating', 'desc');
        break;
      case 'matches':
        fullQuery = fullQuery
          .orderByRaw('(user_sport_stats.wins + user_sport_stats.losses) DESC')
          .orderBy('user_sport_stats.wins', 'desc')
          .orderBy('user_sport_stats.rating', 'desc');
        break;
      case 'elo':
      default:
        fullQuery = fullQuery
          .orderBy('user_sport_stats.rating', 'desc')
          .orderBy('user_sport_stats.wins', 'desc');
        break;
    }

    const allRows = await fullQuery;
    const index = allRows.findIndex((r: any) => r.id === userId);
    if (index === -1) return null;

    const row = allRows[index];
    return {
      rank: index + 1,
      id: row.id,
      name: row.name || 'Anonymous Player',
      avatar_url: row.avatar_url || null,
      sport: row.sport,
      rating: Number(row.rating) || 1200,
      wins: Number(row.wins) || 0,
      losses: Number(row.losses) || 0,
      total_matches: Number(row.total_matches) || 0,
      win_rate: Number(row.win_rate) || 0,
      is_current_user: true,
    };
  }
}
