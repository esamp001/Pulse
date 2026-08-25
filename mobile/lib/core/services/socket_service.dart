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

  final StreamController<Map<String, dynamic>> _activeMatchUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onActiveMatchUpdated => _activeMatchUpdatedController.stream;

  bool get isConnected => _isConnected;

  void init({String? userId}) {
    if (userId != null) {
      _currentUserId = userId;
    }

    if (!dotenv.isInitialized) {
      return;
    }

    if (_socket != null && _socket!.connected) {
      if (_currentUserId != null) {
        _socket?.emit('join_user', {'userId': _currentUserId});
      }
      return;
    }

    try {
      final rawBaseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:5000/api/v1').trim();
      final uri = Uri.parse(rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl');
      final portSuffix = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
      final socketUrl = '${uri.scheme}://${uri.host}$portSuffix';

      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('SocketService connected: ${_socket?.id}');
        if (_currentUserId != null) {
          _socket?.emit('join_user', {'userId': _currentUserId});
        }
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint('SocketService disconnected');
      });

      _socket?.on('active_match_updated', (data) {
        debugPrint('SocketService received active_match_updated event');
        if (data is Map<String, dynamic>) {
          _activeMatchUpdatedController.add(data);
        } else {
          _activeMatchUpdatedController.add({'type': 'ACTIVE_MATCH_UPDATED'});
        }
      });
    } catch (e) {
      debugPrint('SocketService init error: $e');
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

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
