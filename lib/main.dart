import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/mood_alert_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  await MoodAlertNotificationService.instance.init();

  runApp(const MoodApp());
}

class MoodApp extends StatelessWidget {
  const MoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Current Mood',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', primarySwatch: Colors.red),
      // Always start from Splash
      home: const SplashScreen(),
      // Define routes to use Navigator.pushNamed if needed
      routes: {
        '/login': (context) => const LoginScreen(),
        // Note: Detection needs userName, we'll send it via standard Navigator for safety
      },
    );
  }
}

Future<String?> signIn(String email, String password) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return null; // نجاح
  } on FirebaseAuthException catch (e) {
    debugPrint('FirebaseAuth error: ${e.code} -- ${e.message}');
    return e.code; // 'user-not-found', 'wrong-password', ...
  } catch (e) {
    debugPrint('Unknown sign in error: $e');
    return 'unknown-error';
  }
}

Future<String?> createUser(String email, String password) async {
  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return null; // نجاح
  } on FirebaseAuthException catch (e) {
    debugPrint('FirebaseAuth createUser error: ${e.code} -- ${e.message}');
    return e.code; // مثال: email-already-in-use, invalid-email, weak-password
  } catch (e) {
    debugPrint('Unknown create user error: $e');
    return 'unknown-error';
  }
}
