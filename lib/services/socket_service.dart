import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SocketService {
  static IO.Socket? _socket;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  static void connect(String userId) {
    if (_socket != null && _socket!.connected) return;

    final backendUrl = dotenv.env['BACKEND_URL']?.replaceAll('/api/', '') ?? 'http://localhost:3002';
    
    debugPrint('🔌 Connecting to Socket: $backendUrl');
    
    _socket = IO.io(backendUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('✅ Socket Connected');
      _socket!.emit('join', userId);
    });

    _socket!.on('notification', (data) {
      debugPrint('🔔 Socket Notification received: $data');
      _showLocalNotification(data['title'], data['msg']);
    });

    _socket!.onDisconnect((_) => debugPrint('❌ Socket Disconnected'));
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static Future<void> showBackgroundAlert(String title, String body) async {
    await _showLocalNotification(title, body);
  }

  static Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_app_notifications',
      'Task Alerts',
      channelDescription: 'Notification channel for task alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: DateTime.now().millisecond % 10000, 
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
