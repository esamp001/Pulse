export interface User {
  id: string;
  name: string;
  email: string;
  password_hash?: string | null;
  rating: number;
  wins: number;
  losses: number;
  created_at: Date;
  updated_at: Date;
}

export interface CreateUserData {
  name: string;
  email: string;
  password_hash?: string;
  rating?: number;
}
