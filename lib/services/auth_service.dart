import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For ChangeNotifier (optional)

class AuthService extends ChangeNotifier {
  // Optional: Extend for Provider
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Signup with email & password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      print('DEBUG: Signup successful - User: ${userCredential.user?.uid}');
      notifyListeners(); // Optional: If using Provider
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Signup Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected Signup Error: $e');
      return null;
    }
  }

  // Login with email & password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('DEBUG: Login successful - User: ${userCredential.user?.uid}');
      notifyListeners(); // Optional
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected Login Error: $e');
      return null;
    }
  }

  // Logout (Enhanced with debug and error handling)
  Future<void> logout() async {
    try {
      print('DEBUG: Starting logout process');
      await _auth.signOut();
      print(
        'DEBUG: Firebase Auth signOut completed - Current user: ${_auth.currentUser?.uid ?? "null"}',
      );
      notifyListeners(); // Optional: Triggers UI rebuilds (e.g., AuthWrapper)
    } on FirebaseAuthException catch (e) {
      print('Logout Error: ${e.code} - ${e.message}');
      rethrow; // Re-throw if needed (e.g., show dialog)
    } catch (e) {
      print('Unexpected Logout Error: $e');
      rethrow;
    }
  }

  // Current user
  User? get currentUser => _auth.currentUser;

  // Stream for auth state changes (useful for auto-redirect)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
