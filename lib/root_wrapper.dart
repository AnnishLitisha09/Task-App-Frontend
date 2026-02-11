import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'components/bottom_nav.dart';
import 'screens/auth/loginpage.dart';
import 'screens/common/acknowledgement_page.dart';

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
    final prefs = await SharedPreferences.getInstance();
    String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setBool('ack_$todayKey', true);
    setState(() => _hasAcknowledged = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: _syncStateAfterLogin);
    }

    if ((_userRole == 'faculty' || _userRole == 'student') &&
        !_hasAcknowledged) {
      return MorningAcknowledgementPage(onAcknowledged: _handleAcknowledge);
    }

    return MainWrapper(userRole: _userRole);
  }
}
