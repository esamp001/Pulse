export interface User {
  id: string;
  name: string;
  email: string;
  password_hash?: string | null;
  rating: number;
  wins: number;
  losses: number;
  is_onboarded: boolean;
  primary_sport?: string;
  avatar_url?: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface CreateUserData {
  name: string;
  email: string;
  password_hash?: string;
  rating?: number;
}
