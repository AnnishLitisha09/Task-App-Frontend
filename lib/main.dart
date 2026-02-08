import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'components/bottom_nav.dart'; // This contains your MainWrapper
import 'screens/auth/loginpage.dart';
import 'screens/common/acknowledgement_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // 1. Initial State Detection
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String userRole = prefs.getString('userRole') ?? 'student';

  // 2. Acknowledgement Logic (Strictly for Faculty)
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
          // PASS THE CLASS VARIABLES, NOT HARD-CODED FALSE
          initialLogin: isLoggedIn,
          initialAck: hasAcknowledgedToday,
          initialRole: userRole,
        ),
      },
    );
  }
}

class RootWrapper extends StatefulWidget {
  final bool initialLogin;
  final bool initialAck;
  final String initialRole;

  const RootWrapper({
    super.key,
    required this.initialLogin,
    required this.initialAck,
    required this.initialRole,
  });

  @override
  State<RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<RootWrapper> {
  late bool _isLoggedIn;
  late bool _hasAcknowledged;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    // Initialize state from the widget parameters passed by main()
    _isLoggedIn = widget.initialLogin;
    _hasAcknowledged = widget.initialAck;
    _userRole = widget.initialRole;
  }

  // This function is called when login is successful to refresh the local state
  void _syncStateAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = true;
      _userRole = prefs.getString('userRole') ?? 'student';

      // Re-check acknowledgement in case they logged in on a new day
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _hasAcknowledged = prefs.getBool('ack_$todayKey') ?? false;
    });
  }

  void _handleAcknowledge() async {
    final prefs = await SharedPreferences.getInstance();
    String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setBool('ack_$todayKey', true);
    setState(() => _hasAcknowledged = true);
  }

  @override
  Widget build(BuildContext context) {
    // STAGE 1: AUTH GATE
    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: _syncStateAfterLogin);
    }

    // STAGE 2: ACKNOWLEDGEMENT GATE (Only if User is Faculty & Student)
    if (_userRole == 'faculty' && !_hasAcknowledged) {
      return MorningAcknowledgementPage(onAcknowledged: _handleAcknowledge);
    }

    if (_userRole == 'student' && !_hasAcknowledged) {
      return MorningAcknowledgementPage(onAcknowledged: _handleAcknowledge);
    }

    // STAGE 3: THE MAIN WRAPPER (Role-Aware)
    return MainWrapper(userRole: _userRole);
  }
}
