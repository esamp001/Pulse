import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/theme/pulse_colors.dart';
import '../../../../main.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';

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
  io.Socket? _socket;
  
  bool _isLoading = false;
  bool _isSocketConnected = false;
  String _matchStatus = 'READY';

  // Scoring Engine State
  int _p1Score = 0;
  int _p2Score = 0;
  int _currentSet = 1;
  int _p1SetsWon = 0;
  int _p2SetsWon = 0;
  List<String> _completedSets = [];
  String _serverPlayer = 'P1'; // 'P1' or 'P2'

  // Undo History Stack
  final List<ScoreStateHistory> _historyStack = [];

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  bool get _isScorer => _match.scorerId != null && _match.scorerId == AuthService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _matchStatus = _match.status;
    _initSocket();
  }


  void _initSocket() {
    try {
      final rawBaseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000');
      // Extract root server URL (e.g. http://10.0.2.2:3000 or http://localhost:3000)
      final uri = Uri.parse(rawBaseUrl);
      final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';

      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.onConnect((_) {
        if (mounted) {
          setState(() => _isSocketConnected = true);
          _socket?.emit('join_match', {
            'matchId': _match.id,
            'userId': AuthService.currentUser?.id,
            'role': 'scorer',
          });
        }
      });


      _socket?.onDisconnect((_) {
        if (mounted) {
          setState(() => _isSocketConnected = false);
        }
      });

      _socket?.on('match_status_changed', (data) {
        if (mounted && data != null && data['status'] != null) {
          setState(() {
            _matchStatus = data['status'];
          });
        }
      });

      _socket?.on('score_updated', (data) {
        if (mounted && data != null) {
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
      });


      _socket?.connect();
    } catch (e) {
      debugPrint('Socket initialization error: $e');
    }
  }

  @override
  void dispose() {
    _socket?.emit('leave_match', {'matchId': _match.id});
    _socket?.disconnect();
    _socket?.dispose();
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
        _socket?.emit('start_match', {'matchId': _match.id});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start match: $e'),
            backgroundColor: PulseColors.error,
          ),
        );
      }
    }
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

      // Check set completion rule (Target 21 points with 2 lead)
      if ((_p1Score >= 21 || _p2Score >= 21) && (_p1Score - _p2Score).abs() >= 2) {
        final setSummary = 'Set $_currentSet: $_p1Score - $_p2Score';
        _completedSets.add(setSummary);
        if (_p1Score > _p2Score) {
          _p1SetsWon++;
        } else {
          _p2SetsWon++;
        }

        _p1Score = 0;
        _p2Score = 0;
        _currentSet++;
      }
    });

    // Broadcast live score via Socket.IO
    _socket?.emit('record_point', {
      'matchId': _match.id,
      'player': targetPlayer,
      'p1Score': _p1Score,
      'p2Score': _p2Score,
      'currentSet': _currentSet,
      'setScores': _completedSets.join(' | '),
    });
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

    // Broadcast undo via Socket.IO
    _socket?.emit('undo_point', {
      'matchId': _match.id,
      'p1Score': _p1Score,
      'p2Score': _p2Score,
      'currentSet': _currentSet,
      'setScores': _completedSets.join(' | '),
    });
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
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSocketConnected
                    ? const Color(0xFF22C55E)
                    : PulseColors.warning,
                border: Border.all(
                  color: (_isSocketConnected
                          ? const Color(0xFF22C55E)
                          : PulseColors.warning)
                      .withValues(alpha: 0.35),
                  width: 2.5,
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
              // Status & Info Header Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATCH STATUS',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
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
                          child: Text(
                            _matchStatus,
                            style: TextStyle(
                              color: _matchStatus == 'LIVE' ? PulseColors.accent : PulseColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CURRENT SET',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SET $_currentSet',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                              Text(
                                _serverPlayer == 'P1' ? '● SERVING' : 'RECEIVING',
                                style: TextStyle(
                                  color: _serverPlayer == 'P1' ? PulseColors.accent : textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
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
                                    color: _serverPlayer == 'P1' ? PulseColors.accent : border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  '$_p1Score',
                                  style: TextStyle(
                                    color: textPrimary,
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
                              Text(
                                _serverPlayer == 'P2' ? '● SERVING' : 'RECEIVING',
                                style: TextStyle(
                                  color: _serverPlayer == 'P2' ? PulseColors.accent : textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
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
                                    color: _serverPlayer == 'P2' ? PulseColors.accent : border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  '$_p2Score',
                                  style: TextStyle(
                                    color: textPrimary,
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

              const SizedBox(height: 24),

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

