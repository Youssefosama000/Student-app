import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Register new student
  Future<String?> register(String email, String password, String name) async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        return 'Firebase is not initialized. Please restart the app.';
      }
      
      debugPrint('Attempting to register user: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        _user = credential.user;
        notifyListeners();
        debugPrint('User registered successfully: ${credential.user!.uid}');
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      // Handle specific error codes
      if (e.code == 'configuration-not-found' || 
          e.code == 'auth/configuration-not-found' ||
          e.message?.toLowerCase().contains('configuration not found') == true ||
          e.message?.toLowerCase().contains('auth/configuration-not-found') == true) {
        return '❌ CONFIGURATION NOT FOUND\n\nEmail/Password authentication is NOT enabled in Firebase Console.\n\nTo fix:\n1. Go to: console.firebase.google.com\n2. Select project: prosfessorapp\n3. Click: Authentication > Sign-in method\n4. Enable: Email/Password\n5. Save and try again';
      }
      return e.message ?? 'Authentication failed: ${e.code}';
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException: ${e.code} - ${e.message}');
      if (e.code == 'configuration-not-found' || 
          e.code == 'auth/configuration-not-found' ||
          e.message?.toLowerCase().contains('configuration not found') == true ||
          e.message?.toLowerCase().contains('auth/configuration-not-found') == true) {
        return '❌ CONFIGURATION NOT FOUND\n\nEmail/Password authentication is NOT enabled in Firebase Console.\n\nTo fix:\n1. Go to: console.firebase.google.com\n2. Select project: prosfessorapp\n3. Click: Authentication > Sign-in method\n4. Enable: Email/Password\n5. Save and try again';
      }
      return 'Firebase error: ${e.message ?? e.code}';
    } catch (e, stackTrace) {
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('configuration not found') || 
          errorString.contains('configuration-not-found')) {
        return '❌ CONFIGURATION NOT FOUND\n\nEmail/Password authentication is NOT enabled in Firebase Console.\n\nTo fix:\n1. Go to: console.firebase.google.com\n2. Select project: prosfessorapp\n3. Click: Authentication > Sign-in method\n4. Enable: Email/Password\n5. Save and try again';
      }
      return 'An error occurred: ${e.toString()}';
    }
  }

  // Login student
  Future<String?> login(String email, String password) async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        return 'Firebase is not initialized. Please restart the app.';
      }
      
      debugPrint('Attempting to login user: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      notifyListeners();
      debugPrint('User logged in successfully: ${credential.user!.uid}');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      // Handle specific error codes
      if (e.code == 'configuration-not-found' || 
          e.code == 'auth/configuration-not-found' ||
          e.message?.toLowerCase().contains('configuration not found') == true ||
          e.message?.toLowerCase().contains('auth/configuration-not-found') == true) {
        return '❌ CONFIGURATION NOT FOUND\n\nEmail/Password authentication is NOT enabled in Firebase Console.\n\nTo fix:\n1. Go to: console.firebase.google.com\n2. Select project: prosfessorapp\n3. Click: Authentication > Sign-in method\n4. Enable: Email/Password\n5. Save and try again';
      }
      return e.message ?? 'Authentication failed: ${e.code}';
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException: ${e.code} - ${e.message}');
      if (e.code == 'configuration-not-found' || 
          e.code == 'auth/configuration-not-found' ||
          e.message?.toLowerCase().contains('configuration not found') == true ||
          e.message?.toLowerCase().contains('auth/configuration-not-found') == true) {
        return '❌ CONFIGURATION NOT FOUND\n\nEmail/Password authentication is NOT enabled in Firebase Console.\n\nTo fix:\n1. Go to: console.firebase.google.com\n2. Select project: prosfessorapp\n3. Click: Authentication > Sign-in method\n4. Enable: Email/Password\n5. Save and try again';
      }
      return 'Firebase error: ${e.message ?? e.code}';
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('configuration not found') || 
          errorString.contains('configuration-not-found')) {
        return '❌ CONFIGURATION NOT FOUND\n\nEmail/Password authentication is NOT enabled in Firebase Console.\n\nTo fix:\n1. Go to: console.firebase.google.com\n2. Select project: prosfessorapp\n3. Click: Authentication > Sign-in method\n4. Enable: Email/Password\n5. Save and try again';
      }
      return 'An error occurred: ${e.toString()}';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // Get current user name
  String getStudentName() {
    return _user?.displayName ?? _user?.email?.split('@')[0] ?? 'Student';
  }
}

