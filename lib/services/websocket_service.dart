import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/services/storage_service.dart';

class WebSocketMessage {
  final String type;
  final String? activityId;
  final dynamic data;
  final int? timestamp;

  WebSocketMessage({
    required this.type,
    this.activityId,
    this.data,
    this.timestamp,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      activityId: json['activityId'],
      data: json['data'],
      timestamp: json['timestamp'],
    );
  }
}

class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();

  WebSocketChannel? _channel;
  final RxBool isConnected = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxString connectionStatus = 'disconnected'.obs;
  final RxString lastError = ''.obs;
  
  StreamSubscription? _subscription;
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  final Set<String> _pendingSubscriptions = {};
  final Set<String> _subscribedActivities = {};
  String? _currentUserId;

  Future<void> connect() async {
    if (_channel != null && isConnected.value) {
      return;
    }

    final token = StorageService.getToken();
    if (token == null || token.isEmpty) {
      connectionStatus.value = 'no_token';
      lastError.value = '没有登录token';
      return;
    }

    try {
      connectionStatus.value = 'connecting';
      lastError.value = '';
      
      final wsUrl = ApiConfig.baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://') + '/ws/journal';
      
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      
      isConnected.value = true;
      connectionStatus.value = 'connected';
      _sendAuth(token);
      
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      connectionStatus.value = 'error';
      lastError.value = e.toString();
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  void _sendAuth(String token) {
    _send({'action': 'auth', 'token': token});
  }

  void subscribeActivity(String activityId) {
    if (_subscribedActivities.contains(activityId)) {
      return;
    }
    
    if (isAuthenticated.value) {
      _subscribedActivities.add(activityId);
      _sendSubscribe(activityId);
    } else {
      _pendingSubscriptions.add(activityId);
    }
  }

  void _sendSubscribe(String activityId) {
    _send({'action': 'subscribe', 'activityId': activityId});
  }

  void unsubscribeActivity(String activityId) {
    _subscribedActivities.remove(activityId);
    _pendingSubscriptions.remove(activityId);
    
    if (isConnected.value && isAuthenticated.value) {
      _send({'action': 'unsubscribe', 'activityId': activityId});
    }
  }

  void _send(Map<String, dynamic> data) {
    if (_channel != null && isConnected.value) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(json);
      
      if (wsMessage.type == 'AUTH_SUCCESS') {
        _currentUserId = wsMessage.data as String?;
        isAuthenticated.value = true;
        connectionStatus.value = 'authenticated';
        
        for (final activityId in _pendingSubscriptions) {
          _subscribedActivities.add(activityId);
          _sendSubscribe(activityId);
        }
        _pendingSubscriptions.clear();
      } else if (wsMessage.type == 'AUTH_FAILED') {
        lastError.value = '认证失败';
        disconnect();
        return;
      }
      
      _messageController.add(wsMessage);
    } catch (e) {
      // ignore parse errors
    }
  }

  void _onError(dynamic error) {
    lastError.value = error.toString();
    isConnected.value = false;
    isAuthenticated.value = false;
    connectionStatus.value = 'error';
    _scheduleReconnect();
  }

  void _onDone() {
    isConnected.value = false;
    isAuthenticated.value = false;
    connectionStatus.value = 'disconnected';
    _scheduleReconnect();
  }

  Timer? _reconnectTimer;

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (StorageService.isLoggedIn()) {
        connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    isConnected.value = false;
    isAuthenticated.value = false;
    connectionStatus.value = 'disconnected';
    _subscribedActivities.clear();
    _pendingSubscriptions.clear();
    _currentUserId = null;
  }

  @override
  void onClose() {
    disconnect();
    _messageController.close();
    super.onClose();
  }
}
