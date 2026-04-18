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
      .setTransports(['websocket', 'polling']) // Added polling for stability
      .enableAutoConnect()
      .enableReconnection()
      .build());

    _socket!.onConnect((_) {
      debugPrint('✅ Socket Connected');
      _socket!.emit('join', userId);
    });

    _socket!.on('notification', (data) {
      debugPrint('🔔 [SOCKET] Notification data: $data');
      final String title = data['title']?.toString() ?? 'New Alert';
      final String body = data['msg']?.toString() ?? data['body']?.toString() ?? '';
      _showLocalNotification(title, body);
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
      priority: Priority.max,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true, // Critical for some devices to show popup
      category: AndroidNotificationCategory.alarm,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: DateTime.now().hashCode % 2147483647, // More unique ID
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }
}
