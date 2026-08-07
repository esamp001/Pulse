import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../widgets/invite_user_modal.dart';
import 'scorer_screen.dart';


class MatchLobbyScreen extends StatefulWidget {
  final MatchModel match;

  const MatchLobbyScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends State<MatchLobbyScreen> {
  late MatchModel _match;
  final MatchService _matchService = MatchService();
  bool _isLoading = false;
  bool _isAssigning = false;
  Timer? _pollingTimer;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _refreshMatchDetails();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_isAssigning) {
        _refreshMatchDetails(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshMatchDetails({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final updatedMatch = await _matchService.getMatchById(_match.id);
      if (mounted) {
        setState(() {
          _match = updatedMatch;
          if (!silent) _isLoading = false;
        });

        if (['FINISHED', 'CONFIRMED'].contains(updatedMatch.status)) {
          _pollingTimer?.cancel();
        }
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isModalOpen = false;

  void _openInviteModal(String role) {
    if (_isModalOpen) return;
    _isModalOpen = true;

    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: screenWidth > 600 ? 600 : screenWidth,
      ),
      builder: (modalContext) {
        return InviteUserModal(
          role: role,
          matchSport: _match.sport,
          isDarkMode: _isDarkMode,
          onUserSelected: (selectedUser) async {
            Navigator.of(modalContext).pop();
            await _handleAssignUser(role, selectedUser.id);
          },
        );
      },
    ).whenComplete(() {
      _isModalOpen = false;
    });
  }

  Future<void> _handleAssignUser(String role, String userId) async {
    setState(() => _isAssigning = true);
    try {
      final updatedMatch = await _matchService.assignParticipant(
        matchId: _match.id,
        role: role,
        targetUserId: userId,
      );

      if (mounted) {
        setState(() {
          _match = updatedMatch;
        });

        // Re-fetch match details to guarantee 100% joined participant objects
        await _refreshMatchDetails(silent: true);

        if (mounted) {
          final roleLabel = role == 'player2' ? 'Player 2 (Opponent)' : 'Neutral Scorer';
          PulseToast.show(context, '$roleLabel assigned successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        PulseToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  void _copyMatchCode() {
    Clipboard.setData(ClipboardData(text: _match.id));
    PulseToast.show(context, 'Match Code copied to clipboard!');
  }

  Future<void> _handleExitLobby() async {
    final isCreator = AuthService.currentUser?.id == _match.creatorId;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PulseColors.getSurface(_isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
          ),
          title: Text(
            isCreator ? 'Cancel Match Room?' : 'Leave Match Room?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: PulseColors.getTextPrimary(_isDarkMode),
            ),
          ),
          content: Text(
            isCreator
                ? 'Exiting will cancel and close this room for all participants.'
                : 'Are you sure you want to leave this match lobby?',
            style: TextStyle(
              fontSize: 14,
              color: PulseColors.getTextSecondary(_isDarkMode),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Room',
                style: TextStyle(color: PulseColors.getTextSecondary(_isDarkMode)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isCreator ? 'Exit & Cancel' : 'Leave Room'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _matchService.exitMatch(_match.id);
      if (mounted) {
        PulseToast.show(context, isCreator ? 'Match room cancelled.' : 'Left match lobby.');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PulseToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hourNum = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minStr = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    if (isToday) {
      return 'Today at $hourNum:$minStr $period';
    } else {
      final year = dt.year;
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      return '$year-$month-$day at $hourNum:$minStr $period';
    }
  }

  void _handleKickParticipant(String role, String participantName) {
    final roleTitle = role == 'player2' ? 'Player 2 (Opponent)' : 'Neutral Scorer';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: PulseColors.getSurface(_isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: PulseColors.getBorder(_isDarkMode),
              width: 1.0,
            ),
          ),
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PulseColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: PulseColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kick $roleTitle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove $participantName from the match lobby?',
            style: TextStyle(
              fontSize: 14,
              color: PulseColors.getTextSecondary(_isDarkMode),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: PulseColors.getTextSecondary(_isDarkMode),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                setState(() => _isAssigning = true);
                try {
                  final updatedMatch = await _matchService.kickParticipant(
                    matchId: _match.id,
                    role: role,
                  );
                  if (mounted) {
                    setState(() {
                      _match = updatedMatch;
                    });
                    await _refreshMatchDetails(silent: true);
                    if (mounted) {
                      PulseToast.show(context, '$participantName removed from match lobby');
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    PulseToast.show(
                      context,
                      e.toString().replaceAll('Exception: ', ''),
                      isError: true,
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isAssigning = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Kick Participant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUser?.id;
    final isCurrentUserHost = _match.creatorId == currentUserId || _match.player1Id == currentUserId;

    final isReady = _match.status == 'READY' ||
        (_match.player2Id != null &&
         _match.player2Accepted &&
         _match.scorerId != null &&
         _match.scorerAccepted);

    // Soft status colors (Gentle Amber / Teal)
    final statusColor = isReady
        ? PulseColors.accent
        : (_isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD97706));
    final statusBgColor = isReady
        ? PulseColors.accent.withValues(alpha: _isDarkMode ? 0.12 : 0.08)
        : const Color(0xFFF59E0B).withValues(alpha: _isDarkMode ? 0.10 : 0.06);
    final statusBorderColor = isReady
        ? PulseColors.accent.withValues(alpha: _isDarkMode ? 0.30 : 0.22)
        : const Color(0xFFF59E0B).withValues(alpha: _isDarkMode ? 0.30 : 0.22);

    return Scaffold(
      backgroundColor: PulseColors.getBackground(_isDarkMode),
      appBar: AppBar(
        backgroundColor: PulseColors.getSurface(_isDarkMode),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: PulseBackButton(isDarkMode: _isDarkMode),
        ),
        title: Text(
          'Match Lobby',
          style: TextStyle(
            color: PulseColors.getTextPrimary(_isDarkMode),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: PulseColors.accent),
                  )
                : Icon(Icons.refresh_rounded, color: PulseColors.getTextPrimary(_isDarkMode)),
            onPressed: _isLoading ? null : _refreshMatchDetails,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: PulseColors.error),
            tooltip: 'Exit Lobby',
            onPressed: _isLoading ? null : _handleExitLobby,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: PulseColors.getBorder(_isDarkMode),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner (Soft, natural aesthetic)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusBorderColor,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isReady
                          ? PulseColors.accent.withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isReady ? Icons.check_circle_outline_rounded : Icons.hourglass_top_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReady ? 'Lobby Ready for Match' : 'Waiting for participants',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isReady
                              ? 'All player and scorer slots are filled. Ready to play!'
                              : 'Invite Player 2 and assign a neutral Scorer to begin.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: PulseColors.getTextSecondary(_isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Match Info Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PulseColors.getSurface(_isDarkMode),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PulseColors.getBorder(_isDarkMode),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const Icon(Icons.sports_tennis_rounded, color: PulseColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _match.sportDisplayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: PulseColors.getTextPrimary(_isDarkMode),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _copyMatchCode,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: PulseColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: PulseColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                Text(
                                  'ID: ${_match.id.length > 8 ? _match.id.substring(0, 8) : _match.id}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: PulseColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, size: 12, color: PulseColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20, color: PulseColors.getBorder(_isDarkMode)),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: PulseColors.getTextSecondary(_isDarkMode)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _match.location != null && _match.location!.isNotEmpty
                              ? '${_match.venueName} • ${_match.location}'
                              : _match.venueName,
                          style: TextStyle(
                            fontSize: 13,
                            color: PulseColors.getTextSecondary(_isDarkMode),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 16, color: PulseColors.getTextSecondary(_isDarkMode)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDateTime(_match.scheduledAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: PulseColors.getTextSecondary(_isDarkMode),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 16, color: PulseColors.getTextSecondary(_isDarkMode)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_match.setsFormatTitle} (${_match.pointsFormatTitle}, ${_match.winMarginTitle})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PulseColors.getTextPrimary(_isDarkMode),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Section Title: Competitors & Official
            Text(
              'Match Participants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PulseColors.getTextPrimary(_isDarkMode),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Player 1 Card (Host)
            _buildParticipantCard(
              title: 'PLAYER 1 (HOST)',
              participant: _match.player1,
              isHostCard: true,
              roleKey: 'player1',
            ),

            const SizedBox(height: 12),

            // 2. Player 2 Card (Opponent)
            _match.player2 != null
                ? _buildParticipantCard(
                    title: 'PLAYER 2 (OPPONENT)',
                    participant: _match.player2,
                    isHostCard: false,
                    roleKey: 'player2',
                    canKick: isCurrentUserHost,
                    onKick: () => _handleKickParticipant('player2', _match.player2?.name ?? 'Player 2'),
                  )
                : _buildEmptySlotCard(
                    title: 'PLAYER 2 (OPPONENT)',
                    subtitle: 'Invite Player 2 to join match',
                    icon: Icons.person_add_alt_1_rounded,
                    onTap: () => _openInviteModal('player2'),
                  ),

            const SizedBox(height: 12),

            // 3. Scorer Card (Neutral Referee)
            _match.scorer != null
                ? _buildParticipantCard(
                    title: 'NEUTRAL SCORER',
                    participant: _match.scorer,
                    isHostCard: false,
                    roleKey: 'scorer',
                    canKick: isCurrentUserHost,
                    onKick: () => _handleKickParticipant('scorer', _match.scorer?.name ?? 'Scorer'),
                  )
                : _buildEmptySlotCard(
                    title: 'NEUTRAL SCORER',
                    subtitle: 'Assign a referee to record live score',
                    icon: Icons.sports_score_rounded,
                    onTap: () => _openInviteModal('scorer'),
                  ),

            const SizedBox(height: 36),

            // Action Button: Start / Open Scorer Match
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isReady || _match.status == 'LIVE'
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScorerScreen(match: _match),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PulseColors.primary,
                  disabledBackgroundColor: PulseColors.getCard(_isDarkMode),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: PulseColors.textDisabled,
                  elevation: 0, // STRICT NO DROP SHADOW RULE
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isReady || _match.status == 'LIVE'
                          ? PulseColors.primary
                          : PulseColors.getBorder(_isDarkMode),
                    ),
                  ),
                ),
                child: Text(
                  currentUserId == _match.scorerId
                      ? (_match.status == 'LIVE'
                          ? 'Open Scorer Controls'
                          : isReady
                              ? 'Start Match (Scorer)'
                              : 'Waiting for Participants...')
                      : (_match.status == 'LIVE'
                          ? 'View Live Scoreboard'
                          : isReady
                              ? 'View Live Scoreboard'
                              : 'Waiting for Participants...'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),


          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard({
    required String title,
    required MatchParticipantModel? participant,
    required bool isHostCard,
    required String roleKey,
    bool canKick = false,
    VoidCallback? onKick,
  }) {
    final displayName = participant?.name ?? 'Assigned User';
    final ratingText = '${participant?.rating ?? 1200} ELO';
    final initials = participant?.initials ?? '?';
    final avatarUrl = participant?.avatarUrl;

    final bool isAccepted = isHostCard ||
        (roleKey == 'player2' ? _match.player2Accepted : _match.scorerAccepted);
    final statusColor = isAccepted ? const Color(0xFF4CAF50) : PulseColors.warning;
    final statusText = isAccepted ? 'Joined' : 'Pending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseColors.getSurface(_isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PulseColors.getBorder(_isDarkMode),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar representation (Network image or initials avatar)
          CircleAvatar(
            radius: 24,
            backgroundColor: isHostCard
                ? PulseColors.accent.withValues(alpha: 0.2)
                : PulseColors.primary.withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    initials,
                    style: TextStyle(
                      color: isHostCard ? PulseColors.accent : PulseColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: PulseColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isHostCard) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: PulseColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HOST',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Rating Badge & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PulseColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PulseColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  ratingText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: PulseColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (canKick && onKick != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.person_remove_rounded, size: 20, color: PulseColors.error),
              tooltip: 'Kick participant',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onKick,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySlotCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PulseColors.getCard(_isDarkMode),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PulseColors.accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PulseColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: PulseColors.accent.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, color: PulseColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: PulseColors.accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PulseColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+ Invite',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
