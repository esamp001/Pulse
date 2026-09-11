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
      match_type: data.match_type ?? 'singles',
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
    } else if (match.team1_partner_id === userId) {
      await this.matchRepository.updateParticipants(matchId, {
        team1_partner_id: null,
        team1_partner_accepted: false,
        status: 'WAITING',
      });
      return { action: 'left' };
    } else if (match.player2_id === userId) {
      // Player 2 leaving clears slot and reverts status to WAITING
      await this.matchRepository.updateParticipants(matchId, {
        player2_id: null,
        player2_accepted: false,
        status: 'WAITING',
      });
      return { action: 'left' };
    } else if (match.team2_partner_id === userId) {
      await this.matchRepository.updateParticipants(matchId, {
        team2_partner_id: null,
        team2_partner_accepted: false,
        status: 'WAITING',
      });
      return { action: 'left' };
    } else if (match.scorer_id === userId) {
      // Scorer leaving clears slot and reverts status to WAITING
      await this.matchRepository.updateParticipants(matchId, {
        scorer_id: null,
        scorer_accepted: false,
        status: 'WAITING',
      });
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
    role: 'player2' | 'scorer' | 'team1_partner' | 'team2_partner',
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

    if (
      targetUserId === match.player1_id ||
      targetUserId === match.team1_partner_id ||
      targetUserId === match.player2_id ||
      targetUserId === match.team2_partner_id ||
      targetUserId === match.scorer_id
    ) {
      throw new Error('User is already participating in this match');
    }

    let nextTeam1PartnerId = match.team1_partner_id;
    let nextTeam1PartnerAccepted = match.team1_partner_accepted;
    let nextPlayer2Id = match.player2_id;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextTeam2PartnerId = match.team2_partner_id;
    let nextTeam2PartnerAccepted = match.team2_partner_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    const matchSportNorm = (match.sport || 'pickleball').toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim();

    const validateSport = () => {
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
    };

    if (role === 'team1_partner') {
      validateSport();
      nextTeam1PartnerId = targetUserId;
      nextTeam1PartnerAccepted = false;
    } else if (role === 'player2') {
      validateSport();
      nextPlayer2Id = targetUserId;
      nextPlayer2Accepted = false;
    } else if (role === 'team2_partner') {
      validateSport();
      nextTeam2PartnerId = targetUserId;
      nextTeam2PartnerAccepted = false;
    } else if (role === 'scorer') {
      nextScorerId = targetUserId;
      nextScorerAccepted = false;
    }

    // Status remains WAITING until required participants accept
    await this.matchRepository.updateParticipants(matchId, {
      team1_partner_id: nextTeam1PartnerId,
      team1_partner_accepted: nextTeam1PartnerAccepted,
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      team2_partner_id: nextTeam2PartnerId,
      team2_partner_accepted: nextTeam2PartnerAccepted,
      scorer_id: nextScorerId,
      scorer_accepted: nextScorerAccepted,
      status: 'WAITING',
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);

    // Notification Trigger: Match Invitation Sent
    try {
      const inviterName = updatedWithDetails?.player1?.name || 'Match Host';
      const sportName = updatedWithDetails?.sport ? updatedWithDetails.sport.toUpperCase() : 'Pickleball';
      let notifTitle = 'Match Invitation';
      if (role === 'scorer') notifTitle = 'Referee Invitation';
      else if (role === 'team1_partner' || role === 'team2_partner') notifTitle = 'Doubles Teammate Invitation';

      await notificationService.createNotification({
        userId: targetUserId,
        category: 'INVITE',
        title: notifTitle,
        subtitle: `${inviterName} invited you to join a ${sportName} match at ${updatedWithDetails?.venue_name || 'Court #1'}.`,
        payload: { matchId, role },
      });
    } catch (err) {
      console.error('[MatchService assignParticipant Notification Error]:', err);
    }

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

    let nextTeam1PartnerAccepted = match.team1_partner_accepted;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextTeam2PartnerAccepted = match.team2_partner_accepted;
    let nextScorerAccepted = match.scorer_accepted;

    const validateSport = () => {
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
    };

    if (match.team1_partner_id === userId) {
      validateSport();
      nextTeam1PartnerAccepted = true;
    } else if (match.player2_id === userId) {
      validateSport();
      nextPlayer2Accepted = true;
    } else if (match.team2_partner_id === userId) {
      validateSport();
      nextTeam2PartnerAccepted = true;
    } else if (match.scorer_id === userId) {
      nextScorerAccepted = true;
    } else {
      throw new Error('You are not an invited participant in this match');
    }

    let isAllReady = false;
    if (match.match_type === 'doubles') {
      isAllReady = Boolean(
        match.player1_id &&
        match.team1_partner_id &&
        nextTeam1PartnerAccepted &&
        match.player2_id &&
        nextPlayer2Accepted &&
        match.team2_partner_id &&
        nextTeam2PartnerAccepted &&
        match.scorer_id &&
        nextScorerAccepted
      );
    } else {
      isAllReady = Boolean(
        match.player1_id &&
        match.player2_id &&
        nextPlayer2Accepted &&
        match.scorer_id &&
        nextScorerAccepted
      );
    }

    const nextStatus: MatchStatus = isAllReady && match.status === 'WAITING' ? 'READY' : match.status;

    await this.matchRepository.updateParticipants(matchId, {
      team1_partner_accepted: nextTeam1PartnerAccepted,
      player2_accepted: nextPlayer2Accepted,
      team2_partner_accepted: nextTeam2PartnerAccepted,
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
          subtitle: `${accepter?.name || 'Participant'} accepted your match invitation! ${isAllReady ? 'Match is ready.' : ''}`,
          payload: { matchId },
        });
      }
    } catch (err) {
      console.error('[MatchService AcceptInvitation Error]:', err);
    }

    return updatedWithDetails!;
  }

  async declineInvitation(matchId: string, userId: string): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    let nextTeam1PartnerId = match.team1_partner_id;
    let nextTeam1PartnerAccepted = match.team1_partner_accepted;
    let nextPlayer2Id = match.player2_id;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextTeam2PartnerId = match.team2_partner_id;
    let nextTeam2PartnerAccepted = match.team2_partner_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    if (match.team1_partner_id === userId) {
      nextTeam1PartnerId = null;
      nextTeam1PartnerAccepted = false;
    } else if (match.player2_id === userId) {
      nextPlayer2Id = null;
      nextPlayer2Accepted = false;
    } else if (match.team2_partner_id === userId) {
      nextTeam2PartnerId = null;
      nextTeam2PartnerAccepted = false;
    } else if (match.scorer_id === userId) {
      nextScorerId = null;
      nextScorerAccepted = false;
    } else {
      throw new Error('You are not an invited participant in this match');
    }

    await this.matchRepository.updateParticipants(matchId, {
      team1_partner_id: nextTeam1PartnerId,
      team1_partner_accepted: nextTeam1PartnerAccepted,
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      team2_partner_id: nextTeam2PartnerId,
      team2_partner_accepted: nextTeam2PartnerAccepted,
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
    } catch (err) {
      console.error('[MatchService DeclineInvitation Error]:', err);
    }

    return updatedWithDetails!;
  }

  async searchUsers(query: string, requesterId: string) {
    return this.userRepository.searchUsers(query, requesterId);
  }

  async getUserMatches(userId: string): Promise<MatchWithDetails[]> {
    return this.matchRepository.findByUserId(userId);
  }

  async joinMatchByPin(userId: string, pinCode: string, requestedRole?: string): Promise<MatchWithDetails> {
    const cleanPin = (pinCode || '').trim();
    if (!cleanPin || cleanPin.length !== 6) {
      throw new Error('Please enter a valid 6-digit match PIN');
    }

    const match = await this.matchRepository.findByPin(cleanPin);
    if (!match) {
      throw new Error('Invalid or expired match PIN code');
    }

    // Check if user is host or already in match
    if (
      match.player1_id === userId ||
      match.team1_partner_id === userId ||
      match.player2_id === userId ||
      match.team2_partner_id === userId ||
      match.scorer_id === userId
    ) {
      const matchDetails = await this.matchRepository.findByIdWithDetails(match.id);
      return matchDetails!;
    }

    if (!['WAITING', 'READY'].includes(match.status)) {
      throw new Error('This match room is no longer open for joining');
    }

    let roleToAssign = requestedRole;
    if (!roleToAssign) {
      if (match.match_type === 'doubles') {
        if (!match.team1_partner_id) {
          roleToAssign = 'team1_partner';
        } else if (!match.player2_id) {
          roleToAssign = 'player2';
        } else if (!match.team2_partner_id) {
          roleToAssign = 'team2_partner';
        } else if (!match.scorer_id) {
          roleToAssign = 'scorer';
        } else {
          throw new Error('This match room is already full');
        }
      } else {
        if (!match.player2_id) {
          roleToAssign = 'player2';
        } else if (!match.scorer_id) {
          roleToAssign = 'scorer';
        } else {
          throw new Error('This match room is already full');
        }
      }
    }

    let nextTeam1PartnerId = match.team1_partner_id;
    let nextTeam1PartnerAccepted = match.team1_partner_accepted;
    let nextPlayer2Id = match.player2_id;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextTeam2PartnerId = match.team2_partner_id;
    let nextTeam2PartnerAccepted = match.team2_partner_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    if (roleToAssign === 'team1_partner') {
      if (match.team1_partner_id) {
        throw new Error('Team 1 partner slot is already occupied');
      }
      nextTeam1PartnerId = userId;
      nextTeam1PartnerAccepted = true;
    } else if (roleToAssign === 'player2') {
      if (match.player2_id) {
        throw new Error('Player 2 slot is already occupied');
      }
      nextPlayer2Id = userId;
      nextPlayer2Accepted = true; // Auto-accepted via explicit PIN court join
    } else if (roleToAssign === 'team2_partner') {
      if (match.team2_partner_id) {
        throw new Error('Team 2 partner slot is already occupied');
      }
      nextTeam2PartnerId = userId;
      nextTeam2PartnerAccepted = true;
    } else if (roleToAssign === 'scorer') {
      if (match.scorer_id) {
        throw new Error('Scorer slot is already occupied');
      }
      nextScorerId = userId;
      nextScorerAccepted = true; // Auto-accepted via explicit PIN court join
    }

    let isAllReady = false;
    if (match.match_type === 'doubles') {
      isAllReady = Boolean(
        match.player1_id &&
        nextTeam1PartnerId &&
        nextTeam1PartnerAccepted &&
        nextPlayer2Id &&
        nextPlayer2Accepted &&
        nextTeam2PartnerId &&
        nextTeam2PartnerAccepted &&
        nextScorerId &&
        nextScorerAccepted
      );
    } else {
      isAllReady = Boolean(
        match.player1_id &&
        nextPlayer2Id &&
        nextPlayer2Accepted &&
        nextScorerId &&
        nextScorerAccepted
      );
    }

    const nextStatus = isAllReady ? 'READY' : 'WAITING';

    await this.matchRepository.updateParticipants(match.id, {
      team1_partner_id: nextTeam1PartnerId,
      team1_partner_accepted: nextTeam1PartnerAccepted,
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      team2_partner_id: nextTeam2PartnerId,
      team2_partner_accepted: nextTeam2PartnerAccepted,
      scorer_id: nextScorerId,
      scorer_accepted: nextScorerAccepted,
      status: nextStatus,
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(match.id);
    return updatedWithDetails!;
  }

  async switchRole(
    matchId: string,
    userId: string,
    targetRole: 'player1' | 'team1_partner' | 'player2' | 'team2_partner' | 'scorer'
  ): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    if (!['WAITING', 'READY'].includes(match.status)) {
      throw new Error('Cannot switch role after match has started');
    }

    const isPlayer1 = match.player1_id === userId;
    const isTeam1Partner = match.team1_partner_id === userId;
    const isPlayer2 = match.player2_id === userId;
    const isTeam2Partner = match.team2_partner_id === userId;
    const isScorer = match.scorer_id === userId;

    if (!isPlayer1 && !isTeam1Partner && !isPlayer2 && !isTeam2Partner && !isScorer) {
      throw new Error('You are not a participant in this match room');
    }

    let nextPlayer1Id: string | null = match.player1_id;
    let nextTeam1PartnerId = match.team1_partner_id;
    let nextTeam1PartnerAccepted = match.team1_partner_accepted;
    let nextPlayer2Id = match.player2_id;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextTeam2PartnerId = match.team2_partner_id;
    let nextTeam2PartnerAccepted = match.team2_partner_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    const user = await this.userRepository.findById(userId);
    const validateSport = (roleName: string) => {
      if (!user) return;
      const matchSportNorm = (match.sport || 'pickleball').toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim();
      const targetRatings = user.sport_ratings || {};
      const targetRatingKeys = Object.keys(targetRatings).map((k) => k.toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim());
      const primaryNorm = (user.primary_sport || '').toLowerCase().replace(/_/g, ' ').replace(/-/g, ' ').trim();
      const hasSport = targetRatingKeys.includes(matchSportNorm) || primaryNorm === matchSportNorm;
      if (!hasSport) {
        const sportLabel = matchSportNorm === 'table tennis' ? 'Table Tennis' : matchSportNorm[0].toUpperCase() + matchSportNorm.slice(1);
        throw new Error(`Cannot switch to ${roleName}: You have not configured ${sportLabel} in your sport preferences.`);
      }
    };

    // Vacate current slot
    if (isPlayer1) nextPlayer1Id = null;
    if (isTeam1Partner) {
      nextTeam1PartnerId = null;
      nextTeam1PartnerAccepted = false;
    }
    if (isPlayer2) {
      nextPlayer2Id = null;
      nextPlayer2Accepted = false;
    }
    if (isTeam2Partner) {
      nextTeam2PartnerId = null;
      nextTeam2PartnerAccepted = false;
    }
    if (isScorer) {
      nextScorerId = null;
      nextScorerAccepted = false;
    }

    if (targetRole === 'player1') {
      if (match.player1_id && match.player1_id !== userId) {
        throw new Error('Player 1 slot is already occupied');
      }
      validateSport('Player 1');
      nextPlayer1Id = userId;
    } else if (targetRole === 'team1_partner') {
      if (match.team1_partner_id && match.team1_partner_id !== userId) {
        throw new Error('Team 1 Partner slot is already occupied');
      }
      validateSport('Team 1 Partner');
      nextTeam1PartnerId = userId;
      nextTeam1PartnerAccepted = true;
    } else if (targetRole === 'player2') {
      if (match.player2_id && match.player2_id !== userId) {
        throw new Error('Player 2 slot is already occupied');
      }
      validateSport('Player 2');
      nextPlayer2Id = userId;
      nextPlayer2Accepted = true;
    } else if (targetRole === 'team2_partner') {
      if (match.team2_partner_id && match.team2_partner_id !== userId) {
        throw new Error('Team 2 Partner slot is already occupied');
      }
      validateSport('Team 2 Partner');
      nextTeam2PartnerId = userId;
      nextTeam2PartnerAccepted = true;
    } else if (targetRole === 'scorer') {
      if (match.scorer_id && match.scorer_id !== userId) {
        throw new Error('Scorer slot is already occupied');
      }
      nextScorerId = userId;
      nextScorerAccepted = true;
    }

    let isAllReady = false;
    if (match.match_type === 'doubles') {
      isAllReady = Boolean(
        nextPlayer1Id &&
        nextTeam1PartnerId &&
        nextTeam1PartnerAccepted &&
        nextPlayer2Id &&
        nextPlayer2Accepted &&
        nextTeam2PartnerId &&
        nextTeam2PartnerAccepted &&
        nextScorerId &&
        nextScorerAccepted
      );
    } else {
      isAllReady = Boolean(
        nextPlayer1Id &&
        nextPlayer2Id &&
        nextPlayer2Accepted &&
        nextScorerId &&
        nextScorerAccepted
      );
    }

    const nextStatus = isAllReady ? 'READY' : 'WAITING';

    await this.matchRepository.updateParticipants(matchId, {
      player1_id: nextPlayer1Id,
      team1_partner_id: nextTeam1PartnerId,
      team1_partner_accepted: nextTeam1PartnerAccepted,
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      team2_partner_id: nextTeam2PartnerId,
      team2_partner_accepted: nextTeam2PartnerAccepted,
      scorer_id: nextScorerId,
      scorer_accepted: nextScorerAccepted,
      status: nextStatus,
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);
    return updatedWithDetails!;
  }

  async kickParticipant(
    matchId: string,
    requesterId: string,
    role: 'player2' | 'scorer' | 'team1_partner' | 'team2_partner'
  ): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    if (match.creator_id !== requesterId && match.player1_id !== requesterId) {
      throw new Error('Only the match host can kick participants');
    }

    let nextTeam1PartnerId = match.team1_partner_id;
    let nextTeam1PartnerAccepted = match.team1_partner_accepted;
    let nextPlayer2Id = match.player2_id;
    let nextPlayer2Accepted = match.player2_accepted;
    let nextTeam2PartnerId = match.team2_partner_id;
    let nextTeam2PartnerAccepted = match.team2_partner_accepted;
    let nextScorerId = match.scorer_id;
    let nextScorerAccepted = match.scorer_accepted;

    if (role === 'team1_partner') {
      nextTeam1PartnerId = null;
      nextTeam1PartnerAccepted = false;
    } else if (role === 'player2') {
      nextPlayer2Id = null;
      nextPlayer2Accepted = false;
    } else if (role === 'team2_partner') {
      nextTeam2PartnerId = null;
      nextTeam2PartnerAccepted = false;
    } else if (role === 'scorer') {
      nextScorerId = null;
      nextScorerAccepted = false;
    }

    await this.matchRepository.updateParticipants(matchId, {
      team1_partner_id: nextTeam1PartnerId,
      team1_partner_accepted: nextTeam1PartnerAccepted,
      player2_id: nextPlayer2Id,
      player2_accepted: nextPlayer2Accepted,
      team2_partner_id: nextTeam2PartnerId,
      team2_partner_accepted: nextTeam2PartnerAccepted,
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

    // Allow creator, player 1, partners, or assigned scorer to update match status
    const isParticipant =
      match.creator_id === requesterId ||
      match.player1_id === requesterId ||
      match.team1_partner_id === requesterId ||
      match.player2_id === requesterId ||
      match.team2_partner_id === requesterId ||
      match.scorer_id === requesterId;

    if (!isParticipant) {
      throw new Error('Only match participants or the scorer can update match status');
    }

    await this.matchRepository.updateParticipants(matchId, { status });
    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);
    return updatedWithDetails!;
  }

  private async calculateAndApplyElo(
    match: Match,
    winnerId: string,
    matchId: string
  ): Promise<number> {
    const isDoubles = match.match_type === 'doubles';
    let ratingChange = 25;
    const matchSport = (match.sport || 'pickleball').toLowerCase();

    if (isDoubles) {
      if (
        match.player1_id &&
        match.team1_partner_id &&
        match.player2_id &&
        match.team2_partner_id
      ) {
        const p1 = await this.userRepository.findById(match.player1_id);
        const p1Partner = await this.userRepository.findById(match.team1_partner_id);
        const p2 = await this.userRepository.findById(match.player2_id);
        const p2Partner = await this.userRepository.findById(match.team2_partner_id);

        if (p1 && p1Partner && p2 && p2Partner) {
          const isTeam1Winner = winnerId === p1.id || winnerId === p1Partner.id;
          const winningTeam = isTeam1Winner ? [p1, p1Partner] : [p2, p2Partner];
          const losingTeam = isTeam1Winner ? [p2, p2Partner] : [p1, p1Partner];

          const p1Rating = p1.sport_ratings?.[matchSport] ?? p1.rating ?? 1200;
          const p1PartnerRating = p1Partner.sport_ratings?.[matchSport] ?? p1Partner.rating ?? 1200;
          const p2Rating = p2.sport_ratings?.[matchSport] ?? p2.rating ?? 1200;
          const p2PartnerRating = p2Partner.sport_ratings?.[matchSport] ?? p2Partner.rating ?? 1200;

          const team1Avg = Math.round((p1Rating + p1PartnerRating) / 2);
          const team2Avg = Math.round((p2Rating + p2PartnerRating) / 2);

          const winningTeamAvg = isTeam1Winner ? team1Avg : team2Avg;
          const losingTeamAvg = isTeam1Winner ? team2Avg : team1Avg;

          const eloResult = calculateElo(winningTeamAvg, losingTeamAvg, 32);
          ratingChange = eloResult.ratingChange;

          await db.transaction(async (trx) => {
            for (const winner of winningTeam) {
              const currentRating = winner.sport_ratings?.[matchSport] ?? winner.rating ?? 1200;
              await this.userRepository.updateUserRatingAndStats(
                winner.id,
                matchSport,
                currentRating + ratingChange,
                true,
                trx
              );
            }
            for (const loser of losingTeam) {
              const currentRating = loser.sport_ratings?.[matchSport] ?? loser.rating ?? 1200;
              const newRating = Math.max(100, currentRating - ratingChange);
              await this.userRepository.updateUserRatingAndStats(
                loser.id,
                matchSport,
                newRating,
                false,
                trx
              );
            }
          });

          // Dispatch notifications to all 4 participants
          try {
            const winningNames = winningTeam.map((w) => w.name).join(' & ');
            const losingNames = losingTeam.map((l) => l.name).join(' & ');

            for (const winner of winningTeam) {
              const currentRating = winner.sport_ratings?.[matchSport] ?? winner.rating ?? 1200;
              const newRating = currentRating + ratingChange;
              await notificationService.createNotification({
                userId: winner.id,
                category: 'RATING',
                title: `${matchSport.toUpperCase()} ELO Increased`,
                subtitle: `Won doubles match vs ${losingNames} (+${ratingChange} ELO). Current Rating: ${newRating} ELO.`,
                payload: { matchId },
              });

              await notificationService.createNotification({
                userId: winner.id,
                category: 'VERIFIED',
                title: 'Match Outcome Finalized',
                subtitle: `Doubles match outcome vs ${losingNames} confirmed by referee and published to leaderboards.`,
                payload: { matchId },
              });
            }

            for (const loser of losingTeam) {
              const currentRating = loser.sport_ratings?.[matchSport] ?? loser.rating ?? 1200;
              const newRating = Math.max(100, currentRating - ratingChange);
              await notificationService.createNotification({
                userId: loser.id,
                category: 'RATING',
                title: `${matchSport.toUpperCase()} ELO Updated`,
                subtitle: `Doubles match vs ${winningNames} (-${ratingChange} ELO). Current Rating: ${newRating} ELO.`,
                payload: { matchId },
              });

              await notificationService.createNotification({
                userId: loser.id,
                category: 'VERIFIED',
                title: 'Match Outcome Finalized',
                subtitle: `Doubles match outcome vs ${winningNames} confirmed by referee and published to leaderboards.`,
                payload: { matchId },
              });
            }
          } catch (err) {
            console.error('[MatchService calculateAndApplyElo Doubles Notification Error]:', err);
          }
        }
      }
    } else {
      // Singles match
      if (match.player1_id && match.player2_id) {
        const p1 = await this.userRepository.findById(match.player1_id);
        const p2 = await this.userRepository.findById(match.player2_id);

        if (p1 && p2) {
          const isP1Winner = winnerId === p1.id;
          const winner = isP1Winner ? p1 : p2;
          const loser = isP1Winner ? p2 : p1;

          const winnerSportRating = winner.sport_ratings?.[matchSport] ?? winner.rating ?? 1200;
          const loserSportRating = loser.sport_ratings?.[matchSport] ?? loser.rating ?? 1200;

          const eloResult = calculateElo(winnerSportRating, loserSportRating, 32);
          ratingChange = eloResult.ratingChange;

          await db.transaction(async (trx) => {
            await this.userRepository.updateUserRatingAndStats(
              winner.id,
              matchSport,
              eloResult.winnerNewRating,
              true,
              trx
            );
            await this.userRepository.updateUserRatingAndStats(
              loser.id,
              matchSport,
              eloResult.loserNewRating,
              false,
              trx
            );
          });

          try {
            await notificationService.createNotification({
              userId: winner.id,
              category: 'RATING',
              title: `${matchSport.toUpperCase()} ELO Increased`,
              subtitle: `Won match vs ${loser.name} (+${eloResult.ratingChange} ELO). Current Rating: ${eloResult.winnerNewRating} ELO.`,
              payload: { matchId },
            });

            await notificationService.createNotification({
              userId: loser.id,
              category: 'RATING',
              title: `${matchSport.toUpperCase()} ELO Updated`,
              subtitle: `Match vs ${winner.name} (-${eloResult.ratingChange} ELO). Current Rating: ${eloResult.loserNewRating} ELO.`,
              payload: { matchId },
            });

            await notificationService.createNotification({
              userId: winner.id,
              category: 'VERIFIED',
              title: 'Match Outcome Finalized',
              subtitle: `Match outcome vs ${loser.name} confirmed by referee and published to leaderboards.`,
              payload: { matchId },
            });

            await notificationService.createNotification({
              userId: loser.id,
              category: 'VERIFIED',
              title: 'Match Outcome Finalized',
              subtitle: `Match outcome vs ${winner.name} confirmed by referee and published to leaderboards.`,
              payload: { matchId },
            });
          } catch (err) {
            console.error('[MatchService calculateAndApplyElo Singles Notification Error]:', err);
          }
        }
      } else if (winnerId) {
        const winner = await this.userRepository.findById(winnerId);
        if (winner) {
          const currentRating = winner.sport_ratings?.[matchSport] ?? winner.rating ?? 1200;
          await this.userRepository.updateUserRatingAndStats(winner.id, matchSport, currentRating + 25, true);
        }
      }
    }

    return ratingChange;
  }

  async evaluateAndCompleteMatch(
    matchId: string,
    requesterId: string,
    winnerId: string,
    player1SetsWon: number,
    player2SetsWon: number,
    setScores?: string
  ): Promise<MatchWithDetails & { ratingChange?: number }> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    const isParticipant =
      match.creator_id === requesterId ||
      match.player1_id === requesterId ||
      match.team1_partner_id === requesterId ||
      match.player2_id === requesterId ||
      match.team2_partner_id === requesterId ||
      match.scorer_id === requesterId;

    if (!isParticipant) {
      throw new Error('Only match participants or the scorer can finalize the match');
    }

    const isValidWinner =
      winnerId === match.player1_id ||
      winnerId === match.team1_partner_id ||
      winnerId === match.player2_id ||
      winnerId === match.team2_partner_id;

    if (!isValidWinner) {
      throw new Error('Winner must be a player in this match');
    }

    const ratingChange = await this.calculateAndApplyElo(match, winnerId, matchId);

    await this.matchRepository.updateParticipants(matchId, {
      status: 'CONFIRMED',
      winner_id: winnerId,
      player1_sets_won: player1SetsWon,
      player2_sets_won: player2SetsWon,
      set_scores: setScores ?? null,
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);

    return {
      ...updatedWithDetails!,
      ratingChange,
    };
  }

  async applyEloForConfirmedMatch(matchId: string): Promise<MatchWithDetails> {
    const match = await this.matchRepository.findById(matchId);
    if (!match) {
      throw new Error('Match not found');
    }

    if (match.status === 'CONFIRMED') {
      return (await this.matchRepository.findByIdWithDetails(matchId))!;
    }

    if (!match.winner_id) {
      throw new Error('Cannot confirm match without a recorded winner');
    }

    await this.calculateAndApplyElo(match, match.winner_id, matchId);

    await this.matchRepository.updateParticipants(matchId, {
      status: 'CONFIRMED',
    });

    const updatedWithDetails = await this.matchRepository.findByIdWithDetails(matchId);
    return updatedWithDetails!;
  }
}

export default MatchService;


