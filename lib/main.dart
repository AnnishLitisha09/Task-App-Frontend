import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'root_wrapper.dart';
import 'services/venue_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();

  // Seed global reactive venue state from persisted session
  await VenueNotifier.init();

  // 1. Initial State Detection
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String userRole = prefs.getString('userRole') ?? 'student';

  // 2. Acknowledgement Logic
  String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool hasAcknowledgedToday = prefs.getBool('ack_$todayKey') ?? false;

  runApp(
    TaskApp(
      isLoggedIn: isLoggedIn,
      hasAcknowledgedToday: hasAcknowledgedToday,
      userRole: userRole,
    ),
  );
}

class TaskApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasAcknowledgedToday;
  final String userRole;

  const TaskApp({
    super.key,
    required this.isLoggedIn,
    required this.hasAcknowledgedToday,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => RootWrapper(
          key: UniqueKey(),
          initialLogin: isLoggedIn,
          initialAck: hasAcknowledgedToday,
          initialRole: userRole,
        ),
      },
    );
  }
}
