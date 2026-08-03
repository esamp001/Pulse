export interface User {
  id: string;
  name: string;
  email: string;
  password_hash?: string | null;
  rating?: number;
  wins?: number;
  losses?: number;
  is_onboarded: boolean;
  primary_sport?: string;
  sport_ratings?: Record<string, number>;
  sport_stats?: UserSportStat[];
  avatar_url?: string | null;
  has_password?: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface UserSportStat {
  id: string;
  user_id: string;
  sport: string;
  rating: number;
  wins: number;
  losses: number;
  is_primary: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface CreateUserData {
  name: string;
  email: string;
  password_hash?: string;
  rating?: number;
}
