import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/venue_notifier.dart';
import '../../root_wrapper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Small artificial delay to show off the splash
      await Future.delayed(const Duration(milliseconds: 1500));

      await dotenv.load(fileName: ".env");
      final prefs = await SharedPreferences.getInstance();
      await VenueNotifier.init();

      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      String userRole = prefs.getString('userRole') ?? 'student';
      String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      bool hasAcknowledgedToday = prefs.getBool('ack_$todayKey') ?? false;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RootWrapper(
              key: UniqueKey(),
              initialLogin: isLoggedIn,
              initialAck: hasAcknowledgedToday,
              initialRole: userRole,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      debugPrint("Init Error: $e");
      // Fallback in case of error (env loading etc)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RootWrapper(
              key: UniqueKey(),
              initialLogin: false,
              initialAck: false,
              initialRole: 'student',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.jpg',
              width: 250,
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
            .shimmer(delay: 1.seconds, duration: 1500.ms, color: Colors.blue.withOpacity(0.1)),
            
            const SizedBox(height: 16),
            const Text(
              "Authenticating...",
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms),
            
            const SizedBox(height: 60),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFF1F5F9),
                color: Color(0xFF6366F1),
                minHeight: 3,
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
