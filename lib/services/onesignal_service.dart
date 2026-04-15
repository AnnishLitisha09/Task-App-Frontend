import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OneSignalService {
  static Future<void> initialize() async {
    final appId = dotenv.env['ONESIGNAL_APP_ID'];
    if (appId == null) return;

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(appId);

    // Request permissions
    await OneSignal.Notifications.requestPermission(true);
  }

  static Future<void> login(String userId) async {
    await OneSignal.login(userId);
  }

  static Future<void> logout() async {
    await OneSignal.logout();
  }
}
