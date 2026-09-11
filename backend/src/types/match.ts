export type SportType = 'pickleball' | 'tennis' | 'table_tennis';
export type MatchStatus = 'WAITING' | 'READY' | 'LIVE' | 'FINISHED' | 'CONFIRMED';
export type MatchType = 'singles' | 'doubles';

export interface Match {
  id: string;
  creator_id: string;
  player1_id: string;
  match_type: MatchType;
  team1_partner_id?: string | null;
  team1_partner_accepted: boolean;
  player2_id?: string | null;
  player2_accepted: boolean;
  team2_partner_id?: string | null;
  team2_partner_accepted: boolean;
  scorer_id?: string | null;
  scorer_accepted: boolean;
  sport: SportType;
  venue_name: string;
  location?: string | null;
  scheduled_at: Date;
  status: MatchStatus;
  total_sets: number;
  points_to_win_set: number;
  win_by_two: boolean;
  winner_id?: string | null;
  player1_sets_won?: number;
  player2_sets_won?: number;
  set_scores?: string | null;
  pin_code?: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateMatchDTO {
  sport: SportType;
  venue_name: string;
  location?: string;
  scheduled_at: string; // ISO string from client
  match_type?: MatchType;
  total_sets?: number;
  points_to_win_set?: number;
  win_by_two?: boolean;
}

export interface MatchParticipant {
  id: string;
  name: string;
  email: string;
  rating: number;
  avatar_url?: string | null;
  primary_sport?: string | null;
}

export interface MatchWithDetails extends Match {
  player1?: MatchParticipant;
  team1_partner?: MatchParticipant | null;
  player2?: MatchParticipant | null;
  team2_partner?: MatchParticipant | null;
  scorer?: MatchParticipant | null;
}

