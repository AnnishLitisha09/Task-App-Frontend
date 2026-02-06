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

  runApp(TaskApp(
    isLoggedIn: isLoggedIn,
    hasAcknowledgedToday: hasAcknowledgedToday,
  ));
}

class TaskApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasAcknowledgedToday;

  const TaskApp({
    super.key, 
    required this.isLoggedIn, 
    required this.hasAcknowledgedToday
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Task Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
      ),
      // Pass the initial states to the RootWrapper
      home: RootWrapper(
        initialLogin: isLoggedIn,
        initialAck: hasAcknowledgedToday,
      ),
    );
  }
}

class RootWrapper extends StatefulWidget {
  final bool initialLogin;
  final bool initialAck;

  const RootWrapper({
    super.key, 
    required this.initialLogin, 
    required this.initialAck
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

  // Updates local state and refreshes UI
  void _handleLogin() => setState(() => _isLoggedIn = true);
  
  void _handleAcknowledge() => setState(() => _hasAcknowledged = true);

  @override
  Widget build(BuildContext context) {
    // Stage 1: Login Requirement
    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: _handleLogin);
    }

    // Stage 2: Morning Acknowledgement (Rule: Must do before 08:45 AM)
    if (!_hasAcknowledged) {
      return MorningAcknowledgementPage(onAcknowledged: _handleAcknowledge);
    }

    // Stage 3: The Main Dashboard
    return const MainWrapper();
  }
}