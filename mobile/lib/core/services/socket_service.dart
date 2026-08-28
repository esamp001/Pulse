import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentMatchId;
  String? _currentMatchRole;

  final StreamController<Map<String, dynamic>> _activeMatchUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onActiveMatchUpdated =>
      _activeMatchUpdatedController.stream;
  Stream<bool> get onConnectionStateChanged =>
      _connectionStateController.stream;

  bool get isConnected => _socket?.connected ?? _isConnected;
  io.Socket? get socket => _socket;

  void init({String? userId}) {
    if (userId != null && userId.isNotEmpty) {
      _currentUserId = userId;
    }

    if (!dotenv.isInitialized) {
      return;
    }

    if (_socket != null && _socket!.connected) {
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        _socket?.emit('join_user', {'userId': _currentUserId});
      }
      if (_currentMatchId != null && _currentMatchId!.isNotEmpty) {
        _socket?.emit('join_match', {
          'matchId': _currentMatchId,
          'userId': _currentUserId,
          'role': _currentMatchRole ?? 'spectator',
        });
      }
      return;
    }

    if (_socket != null) {
      _socket?.connect();
      return;
    }

    try {
      final rawBaseUrl = dotenv
          .get('API_BASE_URL', fallback: 'http://localhost:5000/api/v1')
          .trim()
          .replaceAll(' ', '');
      final uri = Uri.parse(
          rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl');
      final portSuffix =
          (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
      final socketUrl = '${uri.scheme}://${uri.host}$portSuffix';

      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(double.infinity)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(4000)
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        _connectionStateController.add(true);
        debugPrint('[SocketService] Connected: ${_socket?.id}');
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          _socket?.emit('join_user', {'userId': _currentUserId});
        }
        if (_currentMatchId != null && _currentMatchId!.isNotEmpty) {
          _socket?.emit('join_match', {
            'matchId': _currentMatchId,
            'userId': _currentUserId,
            'role': _currentMatchRole ?? 'spectator',
          });
        }
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        _connectionStateController.add(false);
        debugPrint('[SocketService] Disconnected');
      });

      _socket?.onConnectError((err) {
        _isConnected = false;
        _connectionStateController.add(false);
        debugPrint('[SocketService] Connect Error: $err');
      });

      _socket?.onReconnect((_) {
        _isConnected = true;
        _connectionStateController.add(true);
        debugPrint('[SocketService] Reconnected');
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          _socket?.emit('join_user', {'userId': _currentUserId});
        }
        if (_currentMatchId != null && _currentMatchId!.isNotEmpty) {
          _socket?.emit('join_match', {
            'matchId': _currentMatchId,
            'userId': _currentUserId,
            'role': _currentMatchRole ?? 'spectator',
          });
        }
      });

      _socket?.on('active_match_updated', (data) {
        debugPrint('[SocketService] Received active_match_updated event');
        if (data is Map<String, dynamic>) {
          _activeMatchUpdatedController.add(data);
        } else {
          _activeMatchUpdatedController.add({'type': 'ACTIVE_MATCH_UPDATED'});
        }
      });

      _socket?.connect();
    } catch (e) {
      debugPrint('[SocketService] Init error: $e');
    }
  }

  void joinUserRoom(String userId) {
    _currentUserId = userId;
    if (_socket != null && _socket!.connected) {
      _socket?.emit('join_user', {'userId': userId});
    } else {
      init(userId: userId);
    }
  }

  void joinMatchRoom(String matchId, {String? role, String? userId}) {
    _currentMatchId = matchId;
    if (role != null) _currentMatchRole = role;
    if (userId != null) _currentUserId = userId;

    if (_socket != null && _socket!.connected) {
      _socket?.emit('join_match', {
        'matchId': matchId,
        'userId': _currentUserId,
        'role': _currentMatchRole ?? 'spectator',
      });
    } else {
      init();
    }
  }

  void leaveMatchRoom(String matchId) {
    if (_socket != null && _socket!.connected) {
      _socket?.emit('leave_match', {'matchId': matchId});
    }
    if (_currentMatchId == matchId) {
      _currentMatchId = null;
      _currentMatchRole = null;
    }
  }

  void on(String event, dynamic Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [dynamic Function(dynamic)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void connect() {
    if (_socket != null && !_socket!.connected) {
      _socket?.connect();
    } else if (_socket == null) {
      init();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionStateController.add(false);
  }
}
