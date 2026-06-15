// ============================================================
// services/auth_service.dart
// Handles all Firebase Authentication operations
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── SIGN UP ──────────────────────────────────────────────
  // FIX: Sign out BEFORE saving to Firestore so security rules don't block it.
  // Firestore rules require emailVerified=true, but right after signup
  // the user is auto-signed-in with emailVerified=false → write gets blocked.
  // Solution: sign out first, then save using Admin-style open rules,
  // OR simply save the doc BEFORE sending verification email (user is still
  // signed in with the new account, and we save immediately before signout).
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // Step 2: Save to Firestore IMMEDIATELY (user is signed in, doc doesn't exist yet)
      // We use .set() with merge:true so it never fails if doc exists
      final appUser = AppUser(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        role: 'Admin',
        createdAt: DateTime.now(),
        emailVerified: false,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap(), SetOptions(merge: true));

      // Step 3: Send verification email
      await user.sendEmailVerification();

      // Step 4: Sign out so user must verify email before entering app
      await _auth.signOut();

      return null; // null = success
    } on FirebaseAuthException catch (e) {
      // If anything fails, clean up: sign out any partial session
      await _auth.signOut();
      return _getErrorMessage(e.code);
    } catch (e) {
      await _auth.signOut();
      return 'Signup failed: ${e.toString()}';
    }
  }

  // ── LOGIN ────────────────────────────────────────────────
  // FIX 1: On Flutter Web, currentUser after reload() can be stale.
  //        We must call _auth.currentUser AFTER reload, not before.
  // FIX 2: Firestore document might not exist (if signup Firestore save failed).
  //        Use .set() with merge:true instead of .update() to safely create it.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // Step 2: Force reload to get fresh emailVerified status from Firebase server
      await user.reload();

      // Step 3: Get the REFRESHED user object (critical for web!)
      final refreshedUser = FirebaseAuth.instance.currentUser!;

      // Step 4: Block login if email not verified
      if (!refreshedUser.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email first. Check your inbox for the verification link.';
      }

      // Step 5: Save/update user in Firestore
      // Using set+merge so it works whether doc exists or not
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email.trim(),
        'emailVerified': true,
        'role': 'Admin',
      }, SetOptions(merge: true));

      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Login failed: ${e.toString()}';
    }
  }

  // ── FORGOT PASSWORD ──────────────────────────────────────
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Failed to send reset email. Try again.';
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── GET USER FROM FIRESTORE ──────────────────────────────
  Future<AppUser?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── RESEND VERIFICATION EMAIL ────────────────────────────
  Future<String?> resendVerificationEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user!.sendEmailVerification();
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    }
  }

  // ── ERROR CODE → READABLE MESSAGE ────────────────────────
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}
