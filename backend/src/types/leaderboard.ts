export type LeaderboardCategory = 'elo' | 'win_rate' | 'matches';

export interface LeaderboardEntry {
  rank: number;
  id: string;
  name: string;
  avatar_url: string | null;
  sport: string;
  rating: number;
  wins: number;
  losses: number;
  total_matches: number;
  win_rate: number;
  is_current_user?: boolean;
}

export interface GetLeaderboardOptions {
  sport?: string;
  category: LeaderboardCategory;
  limit?: number;
  offset?: number;
  currentUserId?: string;
}

export interface LeaderboardResponse {
  entries: LeaderboardEntry[];
  currentUserEntry?: LeaderboardEntry | null;
  sport: string;
  category: string;
  hasMore: boolean;
  limit: number;
  offset: number;
}
