import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ikwimpay/providers/auth_provider.dart';
import 'package:ikwimpay/scr/splash_screen.dart'; // Create this file if it doesn't exist
import 'package:ikwimpay/services/update_service.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check for updates when app starts
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(
        const Duration(seconds: 3)); // Wait for app to fully load
    if (mounted) {
      UpdateService().checkForUpdate(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ikwim Pay',
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
