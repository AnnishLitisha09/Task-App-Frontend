import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_page.dart';
import 'store/app_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStore>(
      create: (_) => AppStore(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Inter',
        ),
        home: const SplashPage(),
      ),
    );
  }
}
