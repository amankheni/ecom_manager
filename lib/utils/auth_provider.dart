// ============================================================
// utils/auth_provider.dart
// Provider that holds the current user state across the app
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Listen to Firebase auth state changes and load user data
  void init() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null && firebaseUser.emailVerified) {
        // Load user details from Firestore
        _currentUser = await _authService.getUserFromFirestore(
          firebaseUser.uid,
        );
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  // Set loading state and notify widgets
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Logout and clear user
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
