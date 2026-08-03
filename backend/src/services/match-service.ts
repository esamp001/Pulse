import MatchRepository from '../repositories/match-repository';
import UserRepository from '../repositories/user-repository';
import db from '../database/db';
import notificationService from './notification-service';
import type { Match, MatchWithDetails, CreateMatchDTO, SportType, MatchStatus } from '../types/match';
import { calculateElo } from '../utils/elo';

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

    let totalSets = data.total_sets ?? 3;
    if (![1, 3, 5].includes(totalSets)) {
      totalSets = 3;
    }

    let pointsToWinSet = data.points_to_win_set ?? 11;
    if (pointsToWinSet < 5 || pointsToWinSet > 50) {
      pointsToWinSet = 11;
    }

    const winByTwo = data.win_by_two ?? true;

    const newMatch = await this.matchRepository.create({
      creator_id: userId,
      player1_id: userId, // Creator is player 1
      sport: data.sport,
      venue_name: data.venue_name.trim(),
      location: data.location ? data.location.trim() : null,
      scheduled_at: scheduledDate,
      total_sets: totalSets,
      points_to_win_set: pointsToWinSet,
      win_by_two: winByTwo,
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
      await this.matchRepository.updateParticipants(matchId, { player2_id: null, player2_accepted: false, status: 'WAITING' });
      return { action: 'left' };
    } else if (match.scorer_id === userId) {
      // Scorer leaving clears slot and reverts status to WAITING
      await this.matchRepository.updateParticipants(matchId, { scorer_id: null, scorer_accepted: false, status: 'WAITING' });
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
    let nextPlayer2Accepted = match.player2_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    const matchSportNorm = (match.sport || 'pickleball').toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim();

    if (role === 'player2') {
      if (targetUserId === match.scorer_id) {
        throw new Error('User is already assigned as the Scorer');
      }
      const targetRatings = targetUser.sport_ratings || {};
      const targetRatingKeys = Object.keys(targetRatings).map((k) => k.toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim());
      const primaryNorm = (targetUser.primary_sport || '').toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim();

      const hasSport = targetRatingKeys.includes(matchSportNorm) || primaryNorm === matchSportNorm;

      if (!hasSport) {
        const sportLabel = matchSportNorm === 'table tennis' ? 'Table Tennis' : matchSportNorm[0].toUpperCase() + matchSportNorm.slice(1);
        throw new Error(
          `Cannot invite ${targetUser.name}: This player has not configured ${sportLabel} in their sport preferences.`
        );
      }
      nextPlayer2Id = targetUserId;
      nextPlayer2Accepted = false; // Pending acceptance
    } else if (role === 'scorer') {
      if (targetUserId === match.player2_id) {
        throw new Error('User is already assigned as Player 2');
      }
      nextScorerId = targetUserId;
      nextScorerAccepted = false; // Pending acceptance
    }

    // Status remains WAITING until BOTH accept
    await this.matchRepository.updateParticipants(matchId, {
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      scorer_id: nextScorerId,
      scorer_accepted: nextScorerAccepted,
      status: 'WAITING',
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);

    // Notification Trigger: Match Invitation Sent
    try {
      const inviterName = updatedWithDetails?.player1?.name || 'Match Host';
      const sportName = updatedWithDetails?.sport ? updatedWithDetails.sport.toUpperCase() : 'Pickleball';
      await notificationService.createNotification({
        userId: targetUserId,
        category: 'INVITE',
        title: role === 'player2' ? 'Match Invitation' : 'Referee Invitation',
        subtitle: `${inviterName} invited you to join a ${sportName} match at ${updatedWithDetails?.venue_name || 'Court #1'}.`,
        payload: { matchId, role },
      });
    } catch (_) {}

    return updatedWithDetails!;
  }

  async acceptInvitation(matchId: string, userId: string): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    const matchSportNorm = (match.sport || 'pickleball').toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim();

    let nextPlayer2Accepted = match.player2_accepted;
    let nextScorerAccepted = match.scorer_accepted;

    if (match.player2_id === userId) {
      const userRatings = user.sport_ratings || {};
      const userRatingKeys = Object.keys(userRatings).map((k) => k.toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim());
      const primaryNorm = (user.primary_sport || '').toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim();

      const hasSport = userRatingKeys.includes(matchSportNorm) || primaryNorm === matchSportNorm;

      if (!hasSport) {
        const sportLabel = matchSportNorm === 'table tennis' ? 'Table Tennis' : matchSportNorm[0].toUpperCase() + matchSportNorm.slice(1);
        throw new Error(
          `Cannot accept invitation: You have not configured ${sportLabel} in your sport preferences.`
        );
      }
      nextPlayer2Accepted = true;
    } else if (match.scorer_id === userId) {
      nextScorerAccepted = true;
    } else {
      throw new Error('You are not an invited participant in this match');
    }

    let nextStatus: MatchStatus = match.status;
    if (
      match.player2_id &&
      nextPlayer2Accepted &&
      match.scorer_id &&
      nextScorerAccepted &&
      match.status === 'WAITING'
    ) {
      nextStatus = 'READY';
    }

    await this.matchRepository.updateParticipants(matchId, {
      player2_accepted: nextPlayer2Accepted,
      scorer_accepted: nextScorerAccepted,
      status: nextStatus,
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);

    // Notification Trigger: Invitation Accepted -> Host Notification
    try {
      const accepter = await this.userRepository.findById(userId);
      if (match.player1_id && match.player1_id !== userId) {
        await notificationService.createNotification({
          userId: match.player1_id,
          category: 'INVITE',
          title: 'Invitation Accepted',
          subtitle: `${accepter?.name || 'Participant'} accepted your match invitation! Match is ready.`,
          payload: { matchId },
        });
      }
    } catch (_) {}

    return updatedWithDetails!;
  }

  async declineInvitation(matchId: string, userId: string): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    let nextPlayer2Id = match.player2_id;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    if (match.player2_id === userId) {
      nextPlayer2Id = null;
      nextPlayer2Accepted = false;
    } else if (match.scorer_id === userId) {
      nextScorerId = null;
      nextScorerAccepted = false;
    } else {
      throw new Error('You are not an invited participant in this match');
    }

    await this.matchRepository.updateParticipants(matchId, {
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      scorer_id: nextScorerId,
      scorer_accepted: nextScorerAccepted,
      status: 'WAITING',
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);

    // Notification Trigger: Invitation Declined -> Host Notification
    try {
      const decliner = await this.userRepository.findById(userId);
      if (match.player1_id && match.player1_id !== userId) {
        await notificationService.createNotification({
          userId: match.player1_id,
          category: 'INVITE',
          title: 'Invitation Declined',
          subtitle: `${decliner?.name || 'Participant'} declined your match invitation.`,
          payload: { matchId },
        });
      }
    } catch (_) {}

    return updatedWithDetails!;
  }

  async searchUsers(query: string, requesterId: string) {
    return this.userRepository.searchUsers(query, requesterId);
  }

  async getUserMatches(userId: string): Promise<MatchWithDetails[]> {
    return this.matchRepository.findByUserId(userId);
  }

  async kickParticipant(
    matchId: string,
    requesterId: string,
    role: 'player2' | 'scorer'
  ): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    if (match.creator_id !== requesterId && match.player1_id !== requesterId) {
      throw new Error('Only the match host can kick participants');
    }

    let nextPlayer2Id = match.player2_id;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    if (role === 'player2') {
      nextPlayer2Id = null;
      nextPlayer2Accepted = false;
    } else if (role === 'scorer') {
      nextScorerId = null;
      nextScorerAccepted = false;
    }

    await this.matchRepository.updateParticipants(matchId, {
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      scorer_id: nextScorerId,
      scorer_accepted: nextScorerAccepted,
      status: 'WAITING',
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);
    return updatedWithDetails!;
  }

  async updateMatchStatus(
    matchId: string,
    requesterId: string,
    status: MatchStatus
  ): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    // Allow creator, player 1, or assigned scorer to update match status
    const isParticipant =
      match.creator_id === requesterId ||
      match.player1_id === requesterId ||
      match.scorer_id === requesterId;

    if (!isParticipant) {
      throw new Error('Only match participants or the scorer can update match status');
    }

    await this.matchRepository.updateParticipants(matchId, { status });
    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);
    return updatedWithDetails!;
  }

  async evaluateAndCompleteMatch(
    matchId: string,
    requesterId: string,
    winnerId: string,
    player1SetsWon: number,
    player2SetsWon: number
  ): Promise<MatchWithDetails & { ratingChange?: number }> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    const isParticipant =
      match.creator_id === requesterId ||
      match.player1_id === requesterId ||
      match.scorer_id === requesterId;

    if (!isParticipant) {
      throw new Error('Only match participants or the scorer can finalize the match');
    }

    // Verify winnerId is valid player
    if (winnerId !== match.player1_id && winnerId !== match.player2_id) {
      throw new Error('Winner must be a player in this match');
    }

    let ratingChange = 25;

    // Calculate & Apply True Elo rating changes if both players exist
    if (match.player1_id && match.player2_id) {
      const p1 = await this.userRepository.findById(match.player1_id);
      const p2 = await this.userRepository.findById(match.player2_id);

      if (p1 && p2) {
        const isP1Winner = winnerId === p1.id;
        const winner = isP1Winner ? p1 : p2;
        const loser = isP1Winner ? p2 : p1;

        const matchSport = (match.sport || 'pickleball').toLowerCase();
        const winnerSportRating = winner.sport_ratings?.[matchSport] ?? winner.rating ?? 1200;
        const loserSportRating = loser.sport_ratings?.[matchSport] ?? loser.rating ?? 1200;

        const eloResult = calculateElo(winnerSportRating, loserSportRating, 32);
        ratingChange = eloResult.ratingChange;

        // Update database with new ratings and win/loss records for this specific sport in a transaction
        await db.transaction(async (trx) => {
          await this.userRepository.updateUserRatingAndStats(winner.id, matchSport, eloResult.winnerNewRating, true, trx);
          await this.userRepository.updateUserRatingAndStats(loser.id, matchSport, eloResult.loserNewRating, false, trx);
        });

        // Notification Triggers: Rating & Score Verification
        try {
          // Winner Notification
          await notificationService.createNotification({
            userId: winner.id,
            category: 'RATING',
            title: `${matchSport.toUpperCase()} ELO Increased`,
            subtitle: `Won match vs ${loser.name} (+${eloResult.ratingChange} ELO). Current Rating: ${eloResult.winnerNewRating} ELO.`,
            payload: { matchId },
          });

          // Loser Notification
          await notificationService.createNotification({
            userId: loser.id,
            category: 'RATING',
            title: `${matchSport.toUpperCase()} ELO Updated`,
            subtitle: `Match vs ${winner.name} (-${eloResult.ratingChange} ELO). Current Rating: ${eloResult.loserNewRating} ELO.`,
            payload: { matchId },
          });

          // Match Verification Notifications
          await notificationService.createNotification({
            userId: winner.id,
            category: 'VERIFIED',
            title: 'Match Result Verified',
            subtitle: `Match outcome vs ${loser.name} confirmed and published to leaderboards.`,
            payload: { matchId },
          });

          await notificationService.createNotification({
            userId: loser.id,
            category: 'VERIFIED',
            title: 'Match Result Verified',
            subtitle: `Match outcome vs ${winner.name} confirmed and published to leaderboards.`,
            payload: { matchId },
          });
        } catch (_) {}
      }
    } else if (winnerId) {
      const winner = await this.userRepository.findById(winnerId);
      if (winner) {
        const matchSport = (match.sport || 'pickleball').toLowerCase();
        const currentRating = winner.sport_ratings?.[matchSport] ?? winner.rating ?? 1200;
        await this.userRepository.updateUserRatingAndStats(winner.id, matchSport, currentRating + 25, true);
      }
    }

    await this.matchRepository.updateParticipants(matchId, {
      status: 'FINISHED',
      winner_id: winnerId,
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);
    return {
      ...updatedWithDetails!,
      ratingChange,
    };
  }
}

export default MatchService;

