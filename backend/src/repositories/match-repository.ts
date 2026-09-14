import db from '../database/db';
import type { Match, MatchWithDetails, MatchStatus, SportType, MatchType } from '../types/match';

export interface CreateMatchParams {
  creator_id: string;
  player1_id: string;
  sport: SportType;
  venue_name: string;
  location?: string | null;
  scheduled_at: Date;
  match_type?: MatchType;
  total_sets?: number;
  points_to_win_set?: number;
  win_by_two?: boolean;
}

export interface UpdateMatchParticipantsParams {
  player1_id?: string | null;
  team1_partner_id?: string | null;
  team1_partner_accepted?: boolean;
  player2_id?: string | null;
  player2_accepted?: boolean;
  team2_partner_id?: string | null;
  team2_partner_accepted?: boolean;
  scorer_id?: string | null;
  scorer_accepted?: boolean;
  status?: MatchStatus;
  winner_id?: string | null;
  player1_sets_won?: number;
  player2_sets_won?: number;
  set_scores?: string | null;
}

class MatchRepository {
  private async generateUniquePin(): Promise<string> {
    for (let attempts = 0; attempts < 10; attempts++) {
      const pin = Math.floor(100000 + Math.random() * 900000).toString();
      const existing = await db<Match>('matches')
        .where({ pin_code: pin })
        .whereIn('status', ['WAITING', 'READY', 'LIVE'])
        .first();
      if (!existing) {
        return pin;
      }
    }
    return (Date.now() % 1000000).toString().padStart(6, '0');
  }

  async create(data: CreateMatchParams): Promise<Match> {
    const pin_code = await this.generateUniquePin();
    const [match] = (await db<Match>('matches')
      .insert({
        creator_id: data.creator_id,
        player1_id: data.player1_id,
        match_type: data.match_type ?? 'singles',
        sport: data.sport,
        venue_name: data.venue_name,
        location: data.location || null,
        scheduled_at: data.scheduled_at,
        total_sets: data.total_sets ?? 3,
        points_to_win_set: data.points_to_win_set ?? 11,
        win_by_two: data.win_by_two ?? true,
        pin_code,
        status: 'WAITING',
      })
      .returning('*')) as Match[];

    return match;
  }

  async findById(id: string): Promise<Match | undefined> {
    return db<Match>('matches').where({ id }).first();
  }

  async findByPin(pinCode: string): Promise<Match | undefined> {
    return db<Match>('matches')
      .where({ pin_code: pinCode.trim() })
      .whereIn('status', ['WAITING', 'READY'])
      .orderBy('created_at', 'desc')
      .first();
  }

  private async getParticipantDetails(userId: string, matchSport: string) {
    const user = await db('users')
      .select('id', 'name', 'email', 'avatar_url', 'primary_sport')
      .where({ id: userId })
      .first();

    if (!user) return undefined;

    const sportKey = (matchSport || user.primary_sport || 'pickleball').toLowerCase();
    let sportStat = await db('user_sport_stats')
      .where({ user_id: userId, sport: sportKey })
      .first();

    if (!sportStat) {
      const primaryKey = (user.primary_sport || 'pickleball').toLowerCase();
      sportStat = await db('user_sport_stats')
        .where({ user_id: userId, sport: primaryKey })
        .first();
    }

    return {
      ...user,
      rating: sportStat ? sportStat.rating : 1200,
    };
  }

  async findByIdWithDetails(id: string): Promise<MatchWithDetails | undefined> {
    const match = await db<Match>('matches').where({ id }).first();
    if (!match) return undefined;

    const matchSport = match.sport || 'pickleball';
    const [player1, team1Partner, player2, team2Partner, scorer] = await Promise.all([
      match.player1_id
        ? this.getParticipantDetails(match.player1_id, matchSport)
        : Promise.resolve(null),
      match.team1_partner_id
        ? this.getParticipantDetails(match.team1_partner_id, matchSport)
        : Promise.resolve(null),
      match.player2_id
        ? this.getParticipantDetails(match.player2_id, matchSport)
        : Promise.resolve(null),
      match.team2_partner_id
        ? this.getParticipantDetails(match.team2_partner_id, matchSport)
        : Promise.resolve(null),
      match.scorer_id
        ? this.getParticipantDetails(match.scorer_id, matchSport)
        : Promise.resolve(null),
    ]);

    let courtImageUrl: string | null = null;

    if (match.venue_name) {
      try {
        const matchedCourt = await db('courts')
          .whereILike('name', match.venue_name.trim())
          .whereNotNull('image_url')
          .first();
        if (matchedCourt && matchedCourt.image_url) {
          courtImageUrl = matchedCourt.image_url;
        }
      } catch (courtErr) {
        console.error('[MatchRepository court lookup Error]:', courtErr);
      }
    }

    return {
      ...match,
      court_image_url: courtImageUrl,
      player1: player1 || null,
      team1_partner: team1Partner || null,
      player2: player2 || null,
      team2_partner: team2Partner || null,
      scorer: scorer || null,
    };
  }

  async updateParticipants(id: string, params: UpdateMatchParticipantsParams): Promise<Match> {
    const updatePayload: Record<string, any> = {
      updated_at: new Date(),
    };

    if (params.player1_id !== undefined) updatePayload.player1_id = params.player1_id;
    if (params.team1_partner_id !== undefined) updatePayload.team1_partner_id = params.team1_partner_id;
    if (params.team1_partner_accepted !== undefined) updatePayload.team1_partner_accepted = params.team1_partner_accepted;
    if (params.player2_id !== undefined) updatePayload.player2_id = params.player2_id;
    if (params.player2_accepted !== undefined) updatePayload.player2_accepted = params.player2_accepted;
    if (params.team2_partner_id !== undefined) updatePayload.team2_partner_id = params.team2_partner_id;
    if (params.team2_partner_accepted !== undefined) updatePayload.team2_partner_accepted = params.team2_partner_accepted;
    if (params.scorer_id !== undefined) updatePayload.scorer_id = params.scorer_id;
    if (params.scorer_accepted !== undefined) updatePayload.scorer_accepted = params.scorer_accepted;
    if (params.status !== undefined) updatePayload.status = params.status;
    if (params.winner_id !== undefined) updatePayload.winner_id = params.winner_id;
    if (params.player1_sets_won !== undefined) updatePayload.player1_sets_won = params.player1_sets_won;
    if (params.player2_sets_won !== undefined) updatePayload.player2_sets_won = params.player2_sets_won;
    if (params.set_scores !== undefined) updatePayload.set_scores = params.set_scores;

    const [updatedMatch] = (await db<Match>('matches')
      .where({ id })
      .update(updatePayload)
      .returning('*')) as Match[];

    return updatedMatch;
  }

  async findByUserId(userId: string): Promise<MatchWithDetails[]> {
    const matches = await db<Match>('matches')
      .where(function() {
        this.where({ player1_id: userId })
          .orWhere({ player2_id: userId })
          .orWhere({ team1_partner_id: userId })
          .orWhere({ team2_partner_id: userId });
      })
      .orderBy('scheduled_at', 'desc');

    return Promise.all(
      matches.map(async (match) => {
        const matchSport = match.sport || 'pickleball';
        const [player1, team1Partner, player2, team2Partner, scorer] = await Promise.all([
          this.getParticipantDetails(match.player1_id, matchSport),
          match.team1_partner_id
            ? this.getParticipantDetails(match.team1_partner_id, matchSport)
            : Promise.resolve(null),
          match.player2_id
            ? this.getParticipantDetails(match.player2_id, matchSport)
            : Promise.resolve(null),
          match.team2_partner_id
            ? this.getParticipantDetails(match.team2_partner_id, matchSport)
            : Promise.resolve(null),
          match.scorer_id
            ? this.getParticipantDetails(match.scorer_id, matchSport)
            : Promise.resolve(null),
        ]);
        return {
          ...match,
          player1: player1 || undefined,
          team1_partner: team1Partner || null,
          player2: player2 || null,
          team2_partner: team2Partner || null,
          scorer: scorer || null,
        };
      })
    );
  }

  async findActiveByUserId(userId: string): Promise<Match | undefined> {
    return db<Match>('matches')
      .where(function() {
        this.where({ creator_id: userId })
          .orWhere({ player1_id: userId })
          .orWhere({ player2_id: userId })
          .orWhere({ team1_partner_id: userId })
          .orWhere({ team2_partner_id: userId })
          .orWhere({ scorer_id: userId });
      })
      .whereIn('status', ['WAITING', 'READY', 'LIVE', 'FINISHED'])
      .orderBy('created_at', 'desc')
      .first();
  }


  async delete(id: string): Promise<void> {
    await db('matches').where({ id }).delete();
  }
}

export default MatchRepository;
