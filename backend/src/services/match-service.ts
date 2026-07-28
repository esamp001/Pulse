import MatchRepository from '../repositories/match-repository';
import UserRepository from '../repositories/user-repository';
import type { Match, MatchWithDetails, CreateMatchDTO, SportType, MatchStatus } from '../types/match';

const VALID_SPORTS: SportType[] = ['pickleball', 'tennis', 'table_tennis'];

class MatchService {
  private matchRepository = new MatchRepository();
  private userRepository = new UserRepository();

  async createMatch(userId: string, data: CreateMatchDTO): Promise<Match> {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    const activeMatch = await this.matchRepository.findActiveByUserId(userId);
    if (activeMatch) {
      throw new Error('You already have an active room lobby. Please exit or complete your existing room before creating a new one.');
    }

    if (!VALID_SPORTS.includes(data.sport)) {
      throw new Error('Invalid sport selected. Must be pickleball, tennis, or table_tennis.');
    }

    if (!data.venue_name || data.venue_name.trim().length === 0) {
      throw new Error('Venue name is required');
    }

    const scheduledDate = new Date(data.scheduled_at);
    if (isNaN(scheduledDate.getTime())) {
      throw new Error('Invalid date/time format for scheduled_at');
    }

    const newMatch = await this.matchRepository.create({
      creator_id: userId,
      player1_id: userId, // Creator is player 1
      sport: data.sport,
      venue_name: data.venue_name.trim(),
      location: data.location ? data.location.trim() : null,
      scheduled_at: scheduledDate,
    });

    const withDetails = await this.matchRepository.findByIdWithDetails(newMatch.id);
    return withDetails!;
  }

  async getActiveMatch(userId: string): Promise<MatchWithDetails | null> {
    const activeMatch = await this.matchRepository.findActiveByUserId(userId);

    if (!activeMatch) {
      return null;
    }

    const withDetails = await this.matchRepository.findByIdWithDetails(activeMatch.id);
    return withDetails || null;
  }

  async exitMatch(matchId: string, userId: string): Promise<{ action: 'cancelled' | 'left' }> {
    const match = await this.matchRepository.findById(matchId);
    
    if (!match) {
      throw new Error('Match not found');
    }

    if (match.creator_id === userId || match.player1_id === userId) {
      // Creator exiting cancels/deletes the match room
      await this.matchRepository.delete(matchId);
      return { action: 'cancelled' };
    } else if (match.player2_id === userId) {
      // Player 2 leaving clears slot and reverts status to WAITING
      await this.matchRepository.updateParticipants(matchId, { player2_id: null, status: 'WAITING' });
      return { action: 'left' };
    } else if (match.scorer_id === userId) {
      // Scorer leaving clears slot and reverts status to WAITING
      await this.matchRepository.updateParticipants(matchId, { scorer_id: null, status: 'WAITING' });
      return { action: 'left' };
    } else {
      throw new Error('You are not a participant of this match room');
    }
  }

  async getMatchById(matchId: string): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findByIdWithDetails(matchId);
    if (!match) {
      throw new Error('Match not found');
    }
    return match;
  }

  async assignParticipant(
    matchId: string,
    requesterId: string,
    role: 'player2' | 'scorer',
    targetUserId: string
  ): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    if (match.creator_id !== requesterId && match.player1_id !== requesterId) {
      throw new Error('Only the match creator can invite participants');
    }

    const targetUser = await this.userRepository.findById(targetUserId);
    if (!targetUser) {
      throw new Error('Selected user not found');
    }

    if (targetUserId === match.player1_id) {
      throw new Error('Player 1 cannot be invited as Player 2 or Scorer');
    }

    let nextPlayer2Id = match.player2_id;
    let nextScorerId = match.scorer_id;

    if (role === 'player2') {
      if (targetUserId === match.scorer_id) {
        throw new Error('User is already assigned as the Scorer');
      }
      nextPlayer2Id = targetUserId;
    } else if (role === 'scorer') {
      if (targetUserId === match.player2_id) {
        throw new Error('User is already assigned as Player 2');
      }
      nextScorerId = targetUserId;
    }

    let nextStatus: MatchStatus = match.status;
    if (nextPlayer2Id && nextScorerId && match.status === 'WAITING') {
      nextStatus = 'READY';
    }

    await this.matchRepository.updateParticipants(matchId, {
      player2_id: nextPlayer2Id,
      scorer_id: nextScorerId,
      status: nextStatus,
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);
    return updatedWithDetails!;
  }

  async searchUsers(query: string, requesterId: string) {
    return this.userRepository.searchUsers(query, requesterId);
  }

  async getUserMatches(userId: string): Promise<Match[]> {
    return this.matchRepository.findByUserId(userId);
  }
}

export default MatchService;
