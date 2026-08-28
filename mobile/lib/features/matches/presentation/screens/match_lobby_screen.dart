import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../main.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../widgets/invite_user_modal.dart';
import '../widgets/signal_recovery_banner.dart';
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
  bool _isNavigatingToLive = false;
  bool _isDeviceOffline = false;
  bool _isInitialGracePeriod = true;
  Timer? _gracePeriodTimer;
  Timer? _pollingTimer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _match = widget.match;

    // 2.5s Startup Grace Period: prevents false-positive offline flashes on lobby load
    _gracePeriodTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isInitialGracePeriod = false);
      }
    });

    if (_match.status == 'LIVE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isNavigatingToLive) {
          _isNavigatingToLive = true;
          _pollingTimer?.cancel();
          _socketSub?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ScorerScreen(match: _match),
            ),
          );
        }
      });
    } else {
      _refreshMatchDetails();
      _startPolling();
      _listenToSocketUpdates();
    }
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    Connectivity().checkConnectivity().then((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (mounted) {
        setState(() => _isDeviceOffline = !hasNetwork);
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (mounted) {
        final wasOffline = _isDeviceOffline;
        setState(() => _isDeviceOffline = !hasNetwork);
        if (wasOffline && hasNetwork) {
          // Auto-reconnected!
          _refreshMatchDetails(silent: true);
        }
      }
    });
  }

  void _listenToSocketUpdates() {
    _socketSub = SocketService().onActiveMatchUpdated.listen((_) {
      if (mounted && !_isAssigning && !_isNavigatingToLive) {
        _refreshMatchDetails(silent: true);
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_isAssigning && !_isNavigatingToLive) {
        _refreshMatchDetails(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _gracePeriodTimer?.cancel();
    _connectivitySub?.cancel();
    _socketSub?.cancel();
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

        // Auto-transition all lobby participants (Player 1, Player 2, Scorer)
        // directly to ScorerScreen when match status becomes LIVE
        if (updatedMatch.status == 'LIVE' && !_isNavigatingToLive) {
          _isNavigatingToLive = true;
          _pollingTimer?.cancel();
          _socketSub?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ScorerScreen(match: updatedMatch),
            ),
          );
          return;
        }

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
    final pin = _match.formattedPinCode;
    Clipboard.setData(ClipboardData(text: pin));
    PulseToast.show(context, 'Match PIN $pin copied to clipboard!');
  }

  Future<void> _handleSwitchRole(String targetRole) async {
    final roleLabel = targetRole == 'player2' ? 'Player 2' : 'Neutral Scorer';
    try {
      final updatedMatch = await _matchService.switchParticipantRole(
        matchId: _match.id,
        targetRole: targetRole,
      );
      if (mounted) {
        setState(() {
          _match = updatedMatch;
        });
        PulseToast.showSuccess(context, 'Switched to $roleLabel slot!');
      }
    } catch (e) {
      if (mounted) {
        PulseToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _confirmAndSwitchRole(String targetRole) async {
    final currentUserId = AuthService.currentUser?.id;
    if (currentUserId == null) return;

    final targetLabel = targetRole == 'player2' ? 'Player 2 (Opponent)' : 'Neutral Scorer';
    String currentRoleLabel = 'Participant';
    if (_match.player1Id == currentUserId) {
      currentRoleLabel = 'Player 1 (Host)';
    } else if (_match.player2Id == currentUserId) {
      currentRoleLabel = 'Player 2 (Opponent)';
    } else if (_match.scorerId == currentUserId) {
      currentRoleLabel = 'Neutral Scorer';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PulseColors.getSurface(_isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: PulseColors.getBorder(_isDarkMode)),
          ),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: PulseColors.accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Switch Slot Role?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to move from $currentRoleLabel to $targetLabel?',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: PulseColors.getTextSecondary(_isDarkMode),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: PulseColors.getTextSecondary(_isDarkMode),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.accent,
                foregroundColor: Colors.white,
                elevation: 0, // STRICT NO DROP SHADOW RULE
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirm Move',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _handleSwitchRole(targetRole);
    }
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
            if ((_isDeviceOffline || !SocketService().isConnected) && !_isInitialGracePeriod)
              SignalRecoveryBanner(
                status: SignalConnectionStatus.offline,
                isDarkMode: _isDarkMode,
                onRetry: () => _refreshMatchDetails(),
              ),

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

            const SizedBox(height: 12),

            // High-Visibility Court Join PIN Card (Option A with Copy PIN)
            if (['WAITING', 'READY'].contains(_match.status)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: PulseColors.getSurface(_isDarkMode),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PulseColors.accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.key_rounded,
                            size: 16,
                            color: PulseColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'COURT JOIN PIN CODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: PulseColors.getTextSecondary(_isDarkMode),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 6 Large Segmented Digit Boxes (Grouped 3 + 3)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Builder(
                        builder: (context) {
                          final pin = _match.formattedPinCode;
                          final chars = pin.padRight(6, '0').split('');
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < 6; i++) ...[
                                if (i == 3) const SizedBox(width: 12),
                                Container(
                                  width: 38,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: PulseColors.getBackground(_isDarkMode),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: PulseColors.accent.withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    chars[i],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: PulseColors.accent,
                                    ),
                                  ),
                                ),
                                if (i < 5 && i != 2) const SizedBox(width: 6),
                              ],
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Copy PIN Only Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _copyMatchCode,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text(
                          'Copy PIN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PulseColors.accent,
                          side: BorderSide(
                            color: PulseColors.accent.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Match Info Summary Card (Retains Sport, Location, Date, Set & Points)
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
                    children: [
                      const Icon(Icons.sports_tennis_rounded, color: PulseColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _match.sportDisplayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: PulseColors.getTextPrimary(_isDarkMode),
                          ),
                          overflow: TextOverflow.ellipsis,
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
            _match.player1 != null
                ? _buildParticipantCard(
                    title: 'PLAYER 1 (HOST)',
                    participant: _match.player1,
                    isHostCard: true,
                    roleKey: 'player1',
                    currentUserId: currentUserId,
                  )
                : _buildEmptySlotCard(
                    title: 'PLAYER 1 (HOST)',
                    subtitle: 'Move to compete as Player 1',
                    icon: Icons.person_add_alt_1_rounded,
                    onTapInvite: () => _openInviteModal('player1'),
                    onMoveHere: (currentUserId != null && currentUserId != _match.player1Id)
                        ? () => _confirmAndSwitchRole('player1')
                        : null,
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
                    currentUserId: currentUserId,
                  )
                : _buildEmptySlotCard(
                    title: 'PLAYER 2 (OPPONENT)',
                    subtitle: 'Invite Player 2 to join match',
                    icon: Icons.person_add_alt_1_rounded,
                    onTapInvite: () => _openInviteModal('player2'),
                    onMoveHere: (currentUserId != null && currentUserId != _match.player2Id)
                        ? () => _confirmAndSwitchRole('player2')
                        : null,
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
                    currentUserId: currentUserId,
                  )
                : _buildEmptySlotCard(
                    title: 'NEUTRAL SCORER',
                    subtitle: 'Assign a referee to record live score',
                    icon: Icons.sports_score_rounded,
                    onTapInvite: () => _openInviteModal('scorer'),
                    onMoveHere: (currentUserId != null && currentUserId != _match.scorerId)
                        ? () => _confirmAndSwitchRole('scorer')
                        : null,
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
    String? currentUserId,
  }) {
    final displayName = participant?.name ?? 'Assigned User';
    final ratingText = '${participant?.rating ?? 1200} ELO';
    final initials = participant?.initials ?? '?';
    final avatarUrl = participant?.avatarUrl;
    final bool isCurrentUser = currentUserId != null && participant?.id == currentUserId;

    final bool isAccepted = isHostCard ||
        (roleKey == 'player2' ? _match.player2Accepted : _match.scorerAccepted);
    final statusColor = isAccepted ? const Color(0xFF4CAF50) : PulseColors.warning;
    final statusText = isAccepted ? 'Joined' : 'Pending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? PulseColors.accent.withValues(alpha: _isDarkMode ? 0.08 : 0.04)
            : PulseColors.getSurface(_isDarkMode),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentUser ? PulseColors.accent : PulseColors.getBorder(_isDarkMode),
          width: isCurrentUser ? 2.2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar representation (Network image or initials avatar)
          CircleAvatar(
            radius: 26,
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
                      fontSize: 19,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // User details (Title, Name, ELO Rating at bottom)
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PulseColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'HOST',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PulseColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: PulseColors.getTextPrimary(_isDarkMode),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // ELO Rating moved to the bottom under user name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: PulseColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PulseColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    ratingText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: PulseColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status & Kick action
          Row(
            mainAxisSize: MainAxisSize.min,
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
              if (canKick && onKick != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.person_remove_rounded, size: 20, color: PulseColors.error),
                  tooltip: 'Kick participant',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onKick,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTapInvite,
    VoidCallback? onMoveHere,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PulseColors.getCard(_isDarkMode),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PulseColors.accent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.getTextPrimary(_isDarkMode),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom Action Row: Move Here + Invite Buttons
          Row(
            children: [
              if (onMoveHere != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: onMoveHere,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Move Here',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PulseColors.primary,
                        side: BorderSide(
                          color: PulseColors.primary.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onTapInvite,
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Invite',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0, // STRICT NO DROP SHADOW RULE
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
