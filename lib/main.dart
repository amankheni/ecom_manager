// ============================================================
// main.dart
// App entry point — initializes Firebase and sets up routing
// ============================================================

import 'package:ecom_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'Auth/auth_provider.dart' as app_auth;
import 'Auth/login_screen.dart';
import 'Product Listing/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before running the app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth state provider — available throughout the app
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = app_auth.AuthProvider();
            authProvider.init(); // Start listening to auth changes
            return authProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'E-Commerce Admin',
        debugShowCheckedModeBanner: false,
        theme: getAppTheme(),

        // Use AuthWrapper to decide which screen to show
        home: const AuthWrapper(),
      ),
    );
  }
}

// ── AUTH WRAPPER ─────────────────────────────────────────────
// Listens to Firebase auth state and routes accordingly:
// - Not logged in → LoginScreen
// - Logged in + email verified → HomeScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While Firebase is loading, show a splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 64, color: kPrimaryColor),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: kTextSecondary)),
                ],
              ),
            ),
          );
        }

        // If user is logged in AND email is verified → go to app
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          return const HomeScreen();
        }

        // Otherwise → show login screen
        return const LoginScreen();
      },
    );
  }
}
