import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/splash_page.dart';
import 'store/app_store.dart';
import 'services/socket_service.dart';
import 'services/onesignal_service.dart';
import 'services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This runs in the background even if the app is closed!
    try {
      await dotenv.load(fileName: ".env");

      // Initialize notification plugin
      await SocketService.initialize();

      // Check for unread notifications from API
      final count = await NotificationService().getUnreadCount();

      if (count > 0) {
        // Trigger a local notification
        await SocketService.showBackgroundAlert(
          "New Updates Available",
          "You have $count unread notifications/tasks pending.",
        );
      }
      return Future.value(true);
    } catch (e) {
      print("Background Task Error: $e");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Load Environment Variables
    await dotenv.load(fileName: ".env");

    // 2. Initialize Core Services (OneSignal, Socket, Firebase)
    await Firebase.initializeApp();
    await OneSignalService.initialize();
    await SocketService.initialize();

    // 4. Initialize Workmanager
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  } catch (e) {
    debugPrint("Initialization Warning: $e");
  }

  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStore>(
      create: (_) => AppStore(),
      child: MaterialApp(
        title: 'Task Sync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Inter'),
        home: const SplashPage(),
      ),
    );
  }
}
