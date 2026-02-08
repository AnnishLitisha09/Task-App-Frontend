import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'components/bottom_nav.dart';
import 'screens/auth/loginpage.dart';
import 'screens/student/acknowledgement_page.dart';

void main() async {
  // Required for Shared Preferences and other plugins before runApp
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Logic to determine the initial state
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Check if today's acknowledgement is already done
  String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool hasAcknowledgedToday = prefs.getBool('ack_$todayKey') ?? false;

  runApp(
    TaskApp(isLoggedIn: isLoggedIn, hasAcknowledgedToday: hasAcknowledgedToday),
  );
}

class TaskApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasAcknowledgedToday;

  const TaskApp({
    super.key,
    required this.isLoggedIn,
    required this.hasAcknowledgedToday,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // REMOVE home: RootWrapper(...)

      // Use initialRoute instead. This is the entry point.
      initialRoute: '/',

      routes: {
        '/': (context) {
          // We check the prefs specifically for this route
          // to ensure navigation always has fresh data.
          return RootWrapper(
            initialLogin: false, // On logout, we want this to be false
            initialAck: false, // And this to be false
          );
        },
      },
    );
  }
}

class RootWrapper extends StatefulWidget {
  final bool initialLogin;
  final bool initialAck;

  const RootWrapper({
    super.key,
    required this.initialLogin,
    required this.initialAck,
  });

  @override
  State<RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<RootWrapper> {
  late bool _isLoggedIn;
  late bool _hasAcknowledged;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.initialLogin;
    _hasAcknowledged = widget.initialAck;
  }

  // --- ADD THIS TO RE-SYNC STATE ON NAVIGATION ---
  @override
  void didUpdateWidget(covariant RootWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we navigate back to '/' via pushNamedAndRemoveUntil,
    // the widget might be rebuilt with new initial values.
    _isLoggedIn = widget.initialLogin;
    _hasAcknowledged = widget.initialAck;
  }

  void _handleAcknowledge() => setState(() => _hasAcknowledged = true);

  @override
  Widget build(BuildContext context) {
    // Stage 1: Login Requirement
    // Inside RootWrapper's build method:
    if (!_isLoggedIn) {
      return LoginPage(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      );
    } // Stage 2: Morning Acknowledgement (Rule: Must do before 08:45 AM)
    if (!_hasAcknowledged) {
      return MorningAcknowledgementPage(onAcknowledged: _handleAcknowledge);
    }

    // Stage 3: The Main Dashboard
    return const MainWrapper();
  }
}
