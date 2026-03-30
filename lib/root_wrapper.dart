import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'components/bottom_nav.dart';
import 'screens/auth/loginpage.dart';
import 'screens/common/acknowledgement_page.dart';
import 'services/task_service.dart';

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
    _isLoggedIn = widget.initialLogin;
    _hasAcknowledged = widget.initialAck;
    _userRole = widget.initialRole;
  }

  void _syncStateAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = true;
      _userRole = prefs.getString('userRole') ?? 'student';

      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _hasAcknowledged = prefs.getBool('ack_$todayKey') ?? false;
    });
  }

  void _handleAcknowledge() async {
    try {
      await TaskService().acknowledgeGeneral();
    } catch (e) {
      debugPrint("Acknowledge API Error: $e"); // BUG-18 FIX: Use debugPrint instead of print
    }
    final prefs = await SharedPreferences.getInstance();
    String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setBool('ack_$todayKey', true);
    setState(() => _hasAcknowledged = true);
  }

  bool _isAcknowledgementMandatory() {
    final now = DateTime.now();
    // Mandatory window: 6:00 AM to 8:45 AM
    final startTime = DateTime(now.year, now.month, now.day, 6, 0);
    final endTime = DateTime(now.year, now.month, now.day, 8, 45);
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: _syncStateAfterLogin);
    }

    // Admin goes directly to dashboard
    if (_userRole == 'admin') {
      return MainWrapper(userRole: _userRole);
    }

    // BUG-17 FIX: Included staff in the mandatory acknowledgment window
    if ((_userRole == 'faculty' || _userRole == 'student' || _userRole == 'staff') &&
        !_hasAcknowledged &&
        _isAcknowledgementMandatory()) {
      return MorningAcknowledgementPage(onAcknowledged: _handleAcknowledge);
    }

    // Otherwise show main wrapper (which will handle the "blocked" state if late)
    return MainWrapper(userRole: _userRole);
  }
}
