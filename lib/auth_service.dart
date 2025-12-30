import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Box _settingsBox = Hive.box('settings');

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if current session is Guest
  bool get isGuest => _settingsBox.get('isGuest', defaultValue: false);

  // Stream that combines Firebase and Guest state
  Stream<bool> get sessionStateChanges {
    final controller = StreamController<bool>();
    
    // Listen to Firebase
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        controller.add(true);
      } else {
        controller.add(isGuest);
      }
    });

    // Also watch guest state in settings
    _settingsBox.watch(key: 'isGuest').listen((event) {
      controller.add(event.value || _auth.currentUser != null);
    });

    return controller.stream;
  }

  // Sign up with email and password
  Future<String?> signUp(String email, String password) async {
    try {
      await _settingsBox.put('isGuest', false); // Clear guest if signing up
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  // Login with email and password
  Future<String?> login(String email, String password) async {
    try {
      await _settingsBox.put('isGuest', false); // Clear guest if logging in
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  // Logout
  Future<void> logout() async {
    await _settingsBox.put('isGuest', false);
    await _auth.signOut();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  // Sign in as Guest (Local Only)
  Future<String?> signInAsGuest() async {
    try {
      await _settingsBox.put('isGuest', true);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
