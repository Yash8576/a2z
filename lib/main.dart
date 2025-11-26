import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/sign_in_screen.dart';
import 'ui/main_home_screen.dart';

Future<void> main() async {
  // Initialize Flutter bindings (required for Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase - O(1) per app lifetime
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hub Flux',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Listen to auth state changes - O(1) per auth event
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If user is logged in, show home screen
          if (snapshot.hasData) {
            return const MainHomeScreen();
          }

          // Otherwise show sign in screen
          return const SignInScreen();
        },
      ),
    );
  }
}


