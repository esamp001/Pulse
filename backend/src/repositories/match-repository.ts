import db from '../database/db';
import type { Match, MatchWithDetails, MatchStatus, SportType } from '../types/match';

export interface CreateMatchParams {
  creator_id: string;
  player1_id: string;
  sport: SportType;
  venue_name: string;
  location?: string | null;
  scheduled_at: Date;
}

export interface UpdateMatchParticipantsParams {
  player2_id?: string | null;
  player2_accepted?: boolean;
  scorer_id?: string | null;
  scorer_accepted?: boolean;
  status?: MatchStatus;
}

class MatchRepository {
  async create(data: CreateMatchParams): Promise<Match> {
    const [match] = (await db<Match>('matches')
      .insert({
        creator_id: data.creator_id,
        player1_id: data.player1_id,
        sport: data.sport,
        venue_name: data.venue_name,
        location: data.location || null,
        scheduled_at: data.scheduled_at,
        status: 'WAITING',
      })
      .returning('*')) as Match[];

    return match;
  }

  async findById(id: string): Promise<Match | undefined> {
    return db<Match>('matches').where({ id }).first();
  }

  async findByIdWithDetails(id: string): Promise<MatchWithDetails | undefined> {
    const match = await db<Match>('matches').where({ id }).first();
    if (!match) return undefined;

    const [player1, player2, scorer] = await Promise.all([
      db('users').where({ id: match.player1_id }).select('id', 'name', 'email', 'rating', 'avatar_url', 'primary_sport').first(),
      match.player2_id ? db('users').where({ id: match.player2_id }).select('id', 'name', 'email', 'rating', 'avatar_url', 'primary_sport').first() : Promise.resolve(null),
      match.scorer_id ? db('users').where({ id: match.scorer_id }).select('id', 'name', 'email', 'rating', 'avatar_url', 'primary_sport').first() : Promise.resolve(null),
    ]);

    return {
      ...match,
      player1: player1 || undefined,
      player2: player2 || null,
      scorer: scorer || null,
    };
  }

  async updateParticipants(id: string, params: UpdateMatchParticipantsParams): Promise<Match> {
    const updatePayload: Record<string, any> = {
      updated_at: new Date(),
    };

    if (params.player2_id !== undefined) updatePayload.player2_id = params.player2_id;
    if (params.player2_accepted !== undefined) updatePayload.player2_accepted = params.player2_accepted;
    if (params.scorer_id !== undefined) updatePayload.scorer_id = params.scorer_id;
    if (params.scorer_accepted !== undefined) updatePayload.scorer_accepted = params.scorer_accepted;
    if (params.status !== undefined) updatePayload.status = params.status;

    const [updatedMatch] = (await db<Match>('matches')
      .where({ id })
      .update(updatePayload)
      .returning('*')) as Match[];

    return updatedMatch;
  }

  async findByUserId(userId: string): Promise<Match[]> {
    return db<Match>('matches')
      .where({ creator_id: userId })
      .orWhere({ player1_id: userId })
      .orWhere({ player2_id: userId })
      .orWhere({ scorer_id: userId })
      .orderBy('scheduled_at', 'desc');
  }

  async findActiveByUserId(userId: string): Promise<Match | undefined> {
    return db<Match>('matches')
      .where(function() {
        this.where({ creator_id: userId })
          .orWhere({ player1_id: userId })
          .orWhere({ player2_id: userId })
          .orWhere({ scorer_id: userId });
      })
      .whereIn('status', ['WAITING', 'READY', 'LIVE'])
      .orderBy('created_at', 'desc')
      .first();
  }

  async delete(id: string): Promise<void> {
    await db('matches').where({ id }).delete();
  }
}

export default MatchRepository;
