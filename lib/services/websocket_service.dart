// lib/services/websocket_service.dart

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';


class WebSocketService {
  //static const String _wsBaseUrl = "ws://10.113.49.126:9011"; 
  WebSocketChannel? _channel;
  bool _isManualClose = false;
  
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void connect(int userId) {
    _isManualClose = false;
    final Uri url = Uri.parse("${ApiConfig.socketUrl}?id=$userId");
    
    try {
      _channel = WebSocketChannel.connect(url);
      print("🔌 Connecté au WS : $url");

      _channel!.stream.listen(
        (data) {
          try {
            // Sécurité : conversion si les données arrivent en bytes
            String source = data is Uint8List ? utf8.decode(data) : data.toString();
            final Map<String, dynamic> jsonData = jsonDecode(source);
            _messageController.add(jsonData);
          } catch (e) {
            print("❌ Erreur décodage WS: $e");
          }
        },
        onDone: () => _handleReconnect(userId),
        onError: (e) => _handleReconnect(userId),
      );
    } catch (e) {
      _handleReconnect(userId);
    }
  }

  void _handleReconnect(int userId) {
    if (!_isManualClose) {
      Timer(Duration(seconds: 5), () => connect(userId));
    }
  }

  void disconnect() {
    _isManualClose = true;
    _channel?.sink.close();
  }
}

final webSocketService = WebSocketService();