import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/pulse_colors.dart';
import '../../../../core/widgets/pulse_back_button.dart';
import '../../../../core/widgets/pulse_toast.dart';
import '../../../../main.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../widgets/signal_recovery_banner.dart';
import 'post_match_screen.dart';

class ScoreStateHistory {
  final int p1Score;
  final int p2Score;
  final int currentSet;
  final List<String> setHistory;
  final String? serverPlayer; // 'P1' or 'P2'

  ScoreStateHistory({
    required this.p1Score,
    required this.p2Score,
    required this.currentSet,
    required this.setHistory,
    this.serverPlayer,
  });
}

class ScorerScreen extends StatefulWidget {
  final MatchModel match;

  const ScorerScreen({
    super.key,
    required this.match,
  });

  @override
  State<ScorerScreen> createState() => _ScorerScreenState();
}

class _ScorerScreenState extends State<ScorerScreen> {
  late MatchModel _match;
  final MatchService _matchService = MatchService();
  late ConfettiController _confettiController;
  
  bool _isLoading = false;
  SignalConnectionStatus _connectionStatus = SignalConnectionStatus.online;
  Timer? _autoReconnectTimer;
  Timer? _reconnectedDismissTimer;
  StreamSubscription<bool>? _socketConnectionSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final List<Map<String, dynamic>> _offlineScoreQueue = [];
  String _matchStatus = 'READY';

  // Scoring Engine State
  int _p1Score = 0;
  int _p2Score = 0;
  int _currentSet = 1;
  int _p1SetsWon = 0;
  int _p2SetsWon = 0;
  int _ratingGained = 25;
  List<String> _completedSets = [];
  String _serverPlayer = 'P1'; // 'P1' or 'P2'

  // Minimalist Collapsible Rules Panel
  bool _showRulesPanel = false;

  // Undo History Stack
  final List<ScoreStateHistory> _historyStack = [];

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  bool get _isScorer => _match.scorerId != null && _match.scorerId == AuthService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _match = widget.match;
    _matchStatus = _match.status;
    _connectionStatus = SocketService().isConnected
        ? SignalConnectionStatus.online
        : SignalConnectionStatus.online;

    _initSocketService();
    _initConnectivityListener();
  }

  void _initSocketService() {
    final currentUserId = AuthService.currentUser?.id;
    SocketService().init(userId: currentUserId);
    SocketService().joinMatchRoom(
      _match.id,
      role: _isScorer ? 'scorer' : 'spectator',
      userId: currentUserId,
    );

    _attachSocketListeners();

    _socketConnectionSub = SocketService().onConnectionStateChanged.listen((connected) {
      if (mounted) {
        if (connected) {
          _handleSocketConnected();
        } else {
          _handleSocketDisconnected();
        }
      }
    });

    if (SocketService().isConnected) {
      _handleSocketConnected(isInitial: true);
    }
  }

  void _attachSocketListeners() {
    SocketService().on('match_status_changed', _handleMatchStatusChanged);
    SocketService().on('score_updated', _handleScoreUpdated);
    SocketService().on('match_completed', _handleMatchCompleted);
  }

  void _detachSocketListeners() {
    SocketService().off('match_status_changed', _handleMatchStatusChanged);
    SocketService().off('score_updated', _handleScoreUpdated);
    SocketService().off('match_completed', _handleMatchCompleted);
  }

  void _handleMatchStatusChanged(dynamic data) {
    if (mounted && data != null && data['status'] != null) {
      setState(() {
        _matchStatus = data['status'];
      });
    }
  }

  void _handleScoreUpdated(dynamic data) {
    if (mounted && data != null) {
      // If current user is the SCORER and received a SYNC snapshot, do not downgrade local scores
      if (_isScorer && data['action'] == 'SYNC') {
        final serverP1 = data['p1Score'] as int? ?? 0;
        final serverP2 = data['p2Score'] as int? ?? 0;
        if (_p1Score > serverP1 || _p2Score > serverP2 || _offlineScoreQueue.isNotEmpty) {
          // Scorer is ahead with offline points, push authoritative score to server
          SocketService().emit('record_point', {
            'matchId': _match.id,
            'player': _serverPlayer,
            'p1Score': _p1Score,
            'p2Score': _p2Score,
            'currentSet': _currentSet,
            'setScores': _completedSets.join(' | '),
          });
          return;
        }
      }

      setState(() {
        if (data['p1Score'] != null) _p1Score = data['p1Score'] as int;
        if (data['p2Score'] != null) _p2Score = data['p2Score'] as int;
        if (data['currentSet'] != null) _currentSet = data['currentSet'] as int;
        if (data['player'] == 'P1') {
          _serverPlayer = 'P1';
        } else if (data['player'] == 'P2') {
          _serverPlayer = 'P2';
        }
        if (data['setScores'] != null) {
          final rawSets = data['setScores'] as String;
          _completedSets = rawSets.isNotEmpty ? rawSets.split(' | ') : [];
        }
      });
    }
  }

  void _handleMatchCompleted(dynamic data) {
    if (mounted && data != null) {
      final winnerId = data['winnerId'] as String? ?? _match.player1Id;
      final ratingChange = data['ratingChange'] is int
          ? data['ratingChange'] as int
          : int.tryParse('${data['ratingChange']}') ?? 25;
      final p1Sets = data['p1SetsWon'] is int
          ? data['p1SetsWon'] as int
          : int.tryParse('${data['p1SetsWon']}') ?? _p1SetsWon;
      final p2Sets = data['p2SetsWon'] is int
          ? data['p2SetsWon'] as int
          : int.tryParse('${data['p2SetsWon']}') ?? _p2SetsWon;
      final setScores = data['setScores'] as String? ??
          (_completedSets.isNotEmpty ? _completedSets.join('  •  ') : null);

      setState(() {
        _matchStatus = 'FINISHED';
        _ratingGained = ratingChange;
        _p1SetsWon = p1Sets;
        _p2SetsWon = p2Sets;
        _match = _match.copyWith(
          winnerId: winnerId,
          status: 'FINISHED',
          player1SetsWon: p1Sets,
          player2SetsWon: p2Sets,
          setScores: setScores,
        );
      });
      _showWinnerModal(winnerId);
    }
  }

  void _handleSocketConnected({bool isInitial = false}) {
    _autoReconnectTimer?.cancel();
    if (!mounted) return;
    setState(() {
      if (!isInitial &&
          (_connectionStatus == SignalConnectionStatus.offline ||
              _connectionStatus == SignalConnectionStatus.reconnecting ||
              _offlineScoreQueue.isNotEmpty)) {
        _connectionStatus = SignalConnectionStatus.reconnected;
        _reconnectedDismissTimer?.cancel();
        _reconnectedDismissTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() => _connectionStatus = SignalConnectionStatus.online);
          }
        });
      } else {
        _connectionStatus = SignalConnectionStatus.online;
      }
    });
    _flushOfflineQueue();
  }

  void _handleSocketDisconnected() {
    if (!mounted) return;
    setState(() {
      _connectionStatus = SignalConnectionStatus.offline;
    });
    _startAutoReconnectTimer();
  }

  void _startAutoReconnectTimer() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (SocketService().isConnected) {
        _autoReconnectTimer?.cancel();
        return;
      }
      debugPrint('[ScorerScreen] Reconnecting shared SocketService in background...');
      SocketService().connect();
    });
  }

  void _manualReconnect() {
    setState(() => _connectionStatus = SignalConnectionStatus.reconnecting);
    SocketService().connect();
    _startAutoReconnectTimer();
  }

  void _initConnectivityListener() {
    Connectivity().checkConnectivity().then((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork && mounted) {
        setState(() => _connectionStatus = SignalConnectionStatus.offline);
        _startAutoReconnectTimer();
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (!hasNetwork) {
        if (mounted) {
          setState(() {
            _connectionStatus = SignalConnectionStatus.offline;
          });
          _startAutoReconnectTimer();
        }
      } else {
        if (mounted && (_connectionStatus == SignalConnectionStatus.offline || !SocketService().isConnected)) {
          setState(() => _connectionStatus = SignalConnectionStatus.reconnecting);
          _manualReconnect();
        }
      }
    });
  }

  void _flushOfflineQueue() {
    if (!SocketService().isConnected) return;

    if (_isScorer) {
      SocketService().emit('record_point', {
        'matchId': _match.id,
        'player': _serverPlayer,
        'p1Score': _p1Score,
        'p2Score': _p2Score,
        'currentSet': _currentSet,
        'setScores': _completedSets.join(' | '),
      });
    }

    if (_offlineScoreQueue.isNotEmpty) {
      for (final event in List<Map<String, dynamic>>.from(_offlineScoreQueue)) {
        final eventType = event['type'] as String? ?? 'record_point';
        final payload = event['payload'] as Map<String, dynamic>? ?? {};
        SocketService().emit(eventType, payload);
      }
      _offlineScoreQueue.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _autoReconnectTimer?.cancel();
    _socketConnectionSub?.cancel();
    _connectivitySub?.cancel();
    _reconnectedDismissTimer?.cancel();
    _confettiController.dispose();
    _detachSocketListeners();
    SocketService().leaveMatchRoom(_match.id);
    super.dispose();
  }

  void _saveHistoryState() {
    _historyStack.add(
      ScoreStateHistory(
        p1Score: _p1Score,
        p2Score: _p2Score,
        currentSet: _currentSet,
        setHistory: List.from(_completedSets),
        serverPlayer: _serverPlayer,
      ),
    );
  }

  Future<void> _startMatch() async {
    if (!_isScorer) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final updatedMatch = await _matchService.updateMatchStatus(
        matchId: _match.id,
        status: 'LIVE',
      );

      if (mounted) {
        setState(() {
          _match = updatedMatch;
          _matchStatus = 'LIVE';
          _isLoading = false;
        });

        // Broadcast to socket room
        SocketService().emit('start_match', {'matchId': _match.id});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        PulseToast.show(
          context,
          'Failed to start match: $e',
          isError: true,
        );
      }
    }
  }

  String? get _matchPointState {
    if (_matchStatus != 'LIVE') return null;
    final targetPts = _match.pointsToWinSet;
    final winByTwo = _match.winByTwo;
    final setsToWin = (_match.totalSets / 2).ceil();

    final scoreDiffP1 = _p1Score - _p2Score;
    final scoreDiffP2 = _p2Score - _p1Score;

    final p1AtSetPoint = (_p1Score >= targetPts - 1) && (!winByTwo || scoreDiffP1 >= 1);
    final p2AtSetPoint = (_p2Score >= targetPts - 1) && (!winByTwo || scoreDiffP2 >= 1);

    if (p1AtSetPoint) {
      if (_p1SetsWon == setsToWin - 1) return 'P1_MATCH';
      return 'P1_SET';
    }
    if (p2AtSetPoint) {
      if (_p2SetsWon == setsToWin - 1) return 'P2_MATCH';
      return 'P2_SET';
    }
    return null;
  }

  void _recordPoint(String targetPlayer) {
    if (!_isScorer || _matchStatus != 'LIVE') return;
    HapticFeedback.lightImpact();

    _saveHistoryState();

    setState(() {
      if (targetPlayer == 'P1') {
        _p1Score++;
        _serverPlayer = 'P1';
      } else {
        _p2Score++;
        _serverPlayer = 'P2';
      }

      // Trigger haptic feedback if match point or set point reached
      if (_matchPointState != null) {
        HapticFeedback.mediumImpact();
      }

      // Check set completion rule (Dynamic target points and win by two)
      final targetPts = _match.pointsToWinSet;
      final winByTwo = _match.winByTwo;
      final scoreDiff = (_p1Score - _p2Score).abs();

      final bool isSetWon = (_p1Score >= targetPts || _p2Score >= targetPts) &&
          (!winByTwo || scoreDiff >= 2);

      if (isSetWon) {
        final setSummary = 'Set $_currentSet: $_p1Score - $_p2Score';
        _completedSets.add(setSummary);
        if (_p1Score > _p2Score) {
          _p1SetsWon++;
        } else {
          _p2SetsWon++;
        }

        // Check if match is concluded (majority of totalSets won)
        final setsToWin = (_match.totalSets / 2).ceil();
        if (_p1SetsWon >= setsToWin || _p2SetsWon >= setsToWin) {
          final winnerId = _p1SetsWon >= setsToWin
              ? (_match.player1Id.isNotEmpty ? _match.player1Id : _match.creatorId)
              : (_match.player2Id ?? '');
          _showCrossCheckModal(winnerId);
        } else {
          _p1Score = 0;
          _p2Score = 0;
          _currentSet++;
        }
      }
    });

    // Broadcast live score via Socket.IO or Queue Locally if Offline
    final scorePayload = {
      'matchId': _match.id,
      'player': targetPlayer,
      'p1Score': _p1Score,
      'p2Score': _p2Score,
      'currentSet': _currentSet,
      'setScores': _completedSets.join(' | '),
    };

    if (SocketService().isConnected) {
      SocketService().emit('record_point', scorePayload);
    } else {
      _offlineScoreQueue.add({
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'type': 'record_point',
        'payload': scorePayload,
      });
      // Attempt to ensure connection is active in background
      SocketService().connect();
    }
  }

  void _showCrossCheckModal(String winnerId) {
    final isP1Winner = winnerId == _match.player1Id || winnerId == _match.creatorId;
    final winnerName = isP1Winner
        ? (_match.player1?.name ?? 'Player 1')
        : (_match.player2?.name ?? 'Player 2');

    final setBreakdown = _completedSets.join('  •  ');

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final isDark = _isDarkMode;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PulseColors.getCard(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.amber, size: 30),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Cross-Check & Verify Winner',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: PulseColors.getTextPrimary(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please double-check set scores before official submission.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: PulseColors.getTextSecondary(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Winner & Score Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PulseColors.getBackground(isDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$winnerName Wins!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: PulseColors.getTextPrimary(isDark),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          setBreakdown.isNotEmpty ? setBreakdown : 'Final Set Won',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PulseColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      // Button 1: Get back to the match
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(modalCtx).pop(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(color: PulseColors.getBorder(isDark), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'BACK TO MATCH',
                              style: TextStyle(
                                color: PulseColors.getTextSecondary(isDark),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Button 2: Official Confirmation
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(modalCtx).pop();
                              _finalizeMatch(winnerId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PulseColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'SUBMIT RESULT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _finalizeMatch(String winnerId) async {
    if (_matchStatus == 'FINISHED') return;
    setState(() {
      _matchStatus = 'FINISHED';
    });

    int ratingChange = 25;

    try {
      final result = await _matchService.finalizeMatch(
        matchId: _match.id,
        winnerId: winnerId,
        player1SetsWon: _p1SetsWon,
        player2SetsWon: _p2SetsWon,
        setScores: _completedSets.join('  •  '),
      );
      if (mounted) {
        setState(() {
          _match = result['match'] as MatchModel;
          _ratingGained = result['ratingChange'] as int? ?? 25;
          ratingChange = _ratingGained;
        });
      }
    } catch (e) {
      debugPrint('Error finalizing match: $e');
    }

    SocketService().emit('match_completed', {
      'matchId': _match.id,
      'winnerId': winnerId,
      'ratingChange': ratingChange,
      'p1SetsWon': _p1SetsWon,
      'p2SetsWon': _p2SetsWon,
      'setScores': _completedSets.join('  •  '),
    });

    if (mounted) {
      _showWinnerModal(winnerId);
    }
  }

  void _showWinnerModal(String winnerId) {
    _confettiController.play();
    try {
      HapticFeedback.vibrate();
    } catch (_) {}

    final isP1Winner = winnerId == _match.player1Id || winnerId == _match.creatorId;
    final winnerName = isP1Winner
        ? (_match.player1?.name ?? 'Player 1')
        : (_match.player2?.name ?? 'Player 2');
    final winnerAvatar = isP1Winner ? _match.player1?.avatarUrl : _match.player2?.avatarUrl;
    final winnerInitials = isP1Winner ? (_match.player1?.initials ?? 'P1') : (_match.player2?.initials ?? 'P2');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        alignment: Alignment.topCenter,
        children: [
          Dialog(
            backgroundColor: PulseColors.getSurface(_isDarkMode),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold Trophy Header Circle (Borderless)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 34,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VICTORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: PulseColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$winnerName WINS!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: PulseColors.getTextPrimary(_isDarkMode),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Winner Avatar with Soft Glow Ring (Borderless)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: PulseColors.primary.withValues(alpha: 0.15),
                      backgroundImage: winnerAvatar != null && winnerAvatar.isNotEmpty
                          ? NetworkImage(winnerAvatar)
                          : null,
                      child: winnerAvatar == null || winnerAvatar.isEmpty
                          ? Text(
                              winnerInitials,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: PulseColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Gained Elo Badge (Borderless Pill)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF22C55E)),
                          const SizedBox(width: 6),
                          Text(
                            '+$_ratingGained ELO GAINED',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22C55E),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Confirm Match Button -> Navigates to Post Match Screen
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        final userId = AuthService.currentUser?.id ?? '';
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => PostMatchScreen(
                              match: _match,
                              currentUserId: userId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PulseColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'CONFIRM MATCH',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti Explosion Animation Overlay
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 35,
            emissionFrequency: 0.05,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.2,
            colors: const [
              PulseColors.primary,
              PulseColors.accent,
              Color(0xFFF59E0B),
              Color(0xFF22C55E),
              Color(0xFFEC4899),
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  void _undoPoint() {
    if (!_isScorer || _historyStack.isEmpty) return;
    HapticFeedback.mediumImpact();


    final lastState = _historyStack.removeLast();

    setState(() {
      _p1Score = lastState.p1Score;
      _p2Score = lastState.p2Score;
      _currentSet = lastState.currentSet;
      _completedSets = List.from(lastState.setHistory);
      _serverPlayer = lastState.serverPlayer ?? 'P1';
    });

    // Broadcast undo via Socket.IO or queue locally
    final undoPayload = {
      'matchId': _match.id,
      'p1Score': _p1Score,
      'p2Score': _p2Score,
      'currentSet': _currentSet,
      'setScores': _completedSets.join(' | '),
    };

    if (SocketService().isConnected) {
      SocketService().emit('undo_point', undoPayload);
    } else {
      _offlineScoreQueue.add({
        'type': 'undo_point',
        'payload': undoPayload,
      });
      SocketService().connect();
    }
  }

  void _setServer(String player) {
    if (_serverPlayer == player) return;
    HapticFeedback.lightImpact();
    setState(() {
      _serverPlayer = player;
    });

    final serverPayload = {
      'matchId': _match.id,
      'p1Score': _p1Score,
      'p2Score': _p2Score,
      'currentSet': _currentSet,
      'player': player,
      'setScores': _completedSets.join(' | '),
    };

    if (SocketService().isConnected) {
      SocketService().emit('score_updated', serverPayload);
    } else {
      _offlineScoreQueue.add({
        'type': 'score_updated',
        'payload': serverPayload,
      });
      SocketService().connect();
    }
  }

  void _toggleServer() {
    final nextServer = _serverPlayer == 'P1' ? 'P2' : 'P1';
    _setServer(nextServer);
  }

  Widget _buildRulesMetric(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player1Name = _match.player1?.name ?? 'Player 1';
    final player2Name = _match.player2?.name ?? 'Player 2';
    final bg = PulseColors.getBackground(_isDarkMode);
    final surface = PulseColors.getSurface(_isDarkMode);
    final card = PulseColors.getCard(_isDarkMode);
    final border = PulseColors.getBorder(_isDarkMode);
    final textPrimary = PulseColors.getTextPrimary(_isDarkMode);
    final textSecondary = PulseColors.getTextSecondary(_isDarkMode);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        leading: Center(
          child: PulseBackButton(isDarkMode: _isDarkMode),
        ),
        shape: Border(bottom: BorderSide(color: border, width: 1)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isScorer ? 'NEUTRAL SCORER INTERFACE' : 'LIVE BROADCAST SCOREBOARD',
              style: TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_match.sportDisplayName} • ${_match.venueName}',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: InkWell(
              onTap: () {
                if (_connectionStatus != SignalConnectionStatus.online) {
                  _manualReconnect();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _connectionStatus == SignalConnectionStatus.online || _connectionStatus == SignalConnectionStatus.reconnected
                      ? const Color(0xFF22C55E)
                      : (_connectionStatus == SignalConnectionStatus.reconnecting
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFF59E0B)),
                  border: Border.all(
                    color: (_connectionStatus == SignalConnectionStatus.online || _connectionStatus == SignalConnectionStatus.reconnected
                            ? const Color(0xFF22C55E)
                            : (_connectionStatus == SignalConnectionStatus.reconnecting
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFF59E0B)))
                        .withValues(alpha: 0.35),
                    width: 2.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Minimalist Signal Recovery Top Banner
              SignalRecoveryBanner(
                status: _connectionStatus,
                pendingQueueCount: _offlineScoreQueue.length,
                isDarkMode: _isDarkMode,
                onRetry: () => _manualReconnect(),
              ),

              // Status & Info Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MATCH STATUS',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _matchStatus == 'LIVE'
                                  ? PulseColors.accent.withValues(alpha: 0.15)
                                  : PulseColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _matchStatus == 'LIVE' ? PulseColors.accent : PulseColors.primary,
                                width: 1,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _matchStatus,
                                style: TextStyle(
                                  color: _matchStatus == 'LIVE' ? PulseColors.accent : PulseColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Minimalist Expandable Rules Chip
                    InkWell(
                      onTap: () => setState(() => _showRulesPanel = !_showRulesPanel),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: _showRulesPanel
                              ? PulseColors.primary
                              : PulseColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'RULES',
                              style: TextStyle(
                                color: _showRulesPanel ? Colors.white : PulseColors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _showRulesPanel
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.tune_rounded,
                              size: 13,
                              color: _showRulesPanel ? Colors.white : PulseColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'CURRENT SET',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SET $_currentSet',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Collapsible Minimalist Format Rules Card (Hide & Show)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border.withValues(alpha: 0.6), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildRulesMetric('SETS', _match.setsFormatTitle, textSecondary, textPrimary)),
                      Container(width: 1, height: 24, color: border.withValues(alpha: 0.5)),
                      Expanded(child: _buildRulesMetric('TARGET', _match.pointsFormatTitle, textSecondary, textPrimary)),
                      Container(width: 1, height: 24, color: border.withValues(alpha: 0.5)),
                      Expanded(child: _buildRulesMetric('MARGIN', _match.winMarginTitle, textSecondary, textPrimary)),
                    ],
                  ),
                ),
                crossFadeState: _showRulesPanel
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 20),

              // PRE-MATCH / READY STATE: Start Match Banner
              if (_matchStatus == 'READY') ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PulseColors.accent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'PLAYERS READY ON COURT',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$player1Name  VS  $player2Name',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_isScorer)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _startMatch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PulseColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0, // STRICT NO DROP SHADOW
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'START MATCH',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: border, width: 1),
                          ),
                          child: Text(
                            'Waiting for Scorer (${_match.scorer?.name ?? "Scorer"}) to start the match...',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Main Live Scoreboard Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Idea B: Top Banner Indicator
                    if (_matchPointState != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _matchPointState!.endsWith('_MATCH')
                                  ? Icons.emoji_events_rounded
                                  : Icons.local_fire_department_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _matchPointState == 'P1_MATCH'
                                    ? 'MATCH POINT: $player1Name needs 1 point to win!'
                                    : (_matchPointState == 'P2_MATCH'
                                        ? 'MATCH POINT: $player2Name needs 1 point to win!'
                                        : (_matchPointState == 'P1_SET'
                                            ? 'SET POINT: $player1Name needs 1 point to win Set $_currentSet'
                                            : 'SET POINT: $player2Name needs 1 point to win Set $_currentSet')),
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_completedSets.isNotEmpty) ...[
                      Text(
                        _completedSets.join('  •  '),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: border, height: 1),
                      const SizedBox(height: 16),
                    ],

                    // Scoreboard Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player 1 Column
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _serverPlayer == 'P1' ? PulseColors.accent : border,
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: PulseColors.accent.withValues(alpha: 0.15),
                                  backgroundImage: _match.player1?.avatarUrl != null &&
                                          _match.player1!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(_match.player1!.avatarUrl!)
                                      : null,
                                  child: _match.player1?.avatarUrl == null ||
                                          _match.player1!.avatarUrl!.isEmpty
                                      ? Text(
                                          _match.player1?.initials ?? 'P1',
                                          style: TextStyle(
                                            color: PulseColors.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                player1Name.toUpperCase(),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sets Won: $_p1SetsWon',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: (_isScorer && _matchStatus == 'LIVE') ? () => _setServer('P1') : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _serverPlayer == 'P1'
                                        ? PulseColors.accent.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _serverPlayer == 'P1' ? '● SERVING' : 'RECEIVING',
                                    style: TextStyle(
                                      color: _serverPlayer == 'P1' ? PulseColors.accent : textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_matchPointState == 'P1_SET' || _matchPointState == 'P1_MATCH')
                                        ? const Color(0xFFF59E0B)
                                        : (_serverPlayer == 'P1' ? PulseColors.accent : border),
                                    width: (_matchPointState == 'P1_SET' || _matchPointState == 'P1_MATCH') ? 2.5 : 1.5,
                                  ),
                                ),
                                child: Text(
                                  '$_p1Score',
                                  style: TextStyle(
                                    color: (_matchPointState == 'P1_SET' || _matchPointState == 'P1_MATCH')
                                        ? const Color(0xFFF59E0B)
                                        : textPrimary,
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // VS Divider
                        Padding(
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 40),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        // Player 2 Column
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _serverPlayer == 'P2' ? PulseColors.accent : border,
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: PulseColors.primary.withValues(alpha: 0.15),
                                  backgroundImage: _match.player2?.avatarUrl != null &&
                                          _match.player2!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(_match.player2!.avatarUrl!)
                                      : null,
                                  child: _match.player2?.avatarUrl == null ||
                                          _match.player2!.avatarUrl!.isEmpty
                                      ? Text(
                                          _match.player2?.initials ?? 'P2',
                                          style: TextStyle(
                                            color: PulseColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                player2Name.toUpperCase(),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sets Won: $_p2SetsWon',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: (_isScorer && _matchStatus == 'LIVE') ? () => _setServer('P2') : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _serverPlayer == 'P2'
                                        ? PulseColors.accent.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _serverPlayer == 'P2' ? '● SERVING' : 'RECEIVING',
                                    style: TextStyle(
                                      color: _serverPlayer == 'P2' ? PulseColors.accent : textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_matchPointState == 'P2_SET' || _matchPointState == 'P2_MATCH')
                                        ? const Color(0xFFF59E0B)
                                        : (_serverPlayer == 'P2' ? PulseColors.accent : border),
                                    width: (_matchPointState == 'P2_SET' || _matchPointState == 'P2_MATCH') ? 2.5 : 1.5,
                                  ),
                                ),
                                child: Text(
                                  '$_p2Score',
                                  style: TextStyle(
                                    color: (_matchPointState == 'P2_SET' || _matchPointState == 'P2_MATCH')
                                        ? const Color(0xFFF59E0B)
                                        : textPrimary,
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Full-Width Server Control Button (Restricted to Scorer)
              if (_isScorer && _matchStatus == 'LIVE') ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _toggleServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: card,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: border.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.sync_alt_rounded, size: 18, color: PulseColors.primary),
                    label: Text(
                      'SWITCH SERVER  (${_serverPlayer == 'P1' ? player1Name : player2Name} SERVING)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // POINT RECORDING CONTROLS (Restricted to Scorer)
              if (_isScorer) ...[
                Text(
                  'POINT RECORDING CONTROLS',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 72,
                        child: OutlinedButton(
                          onPressed: _matchStatus == 'LIVE' ? () => _recordPoint('P1') : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: surface,
                            side: BorderSide(
                              color: _matchStatus == 'LIVE' ? PulseColors.accent : border,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+1 POINT',
                                style: TextStyle(
                                  color: _matchStatus == 'LIVE' ? PulseColors.accent : textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                player1Name.toUpperCase(),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 72,
                        child: OutlinedButton(
                          onPressed: _matchStatus == 'LIVE' ? () => _recordPoint('P2') : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: surface,
                            side: BorderSide(
                              color: _matchStatus == 'LIVE' ? PulseColors.accent : border,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+1 POINT',
                                style: TextStyle(
                                  color: _matchStatus == 'LIVE' ? PulseColors.accent : textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                player2Name.toUpperCase(),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // UNDO BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _historyStack.isEmpty ? null : _undoPoint,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: card,
                      side: BorderSide(
                        color: _historyStack.isEmpty ? border : PulseColors.warning,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'UNDO LAST POINT',
                      style: TextStyle(
                        color: _historyStack.isEmpty ? textSecondary : PulseColors.warning,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Broadcast View info card for Players & Spectators
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'BROADCAST VIEW ONLY',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Scoring controls are exclusively operated by the neutral scorer (${_match.scorer?.name ?? "Assigned Scorer"}).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

