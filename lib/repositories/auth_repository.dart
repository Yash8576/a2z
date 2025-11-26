import 'package:firebase_auth/firebase_auth.dart';

/// MAANG-style repository pattern for authentication
/// - Isolates Firebase dependency
/// - Makes testing easier (mock this interface)
/// - Centralizes auth logic
///
/// Time complexity: O(1) for each method (single network call)
/// Space complexity: O(1) (no data structures, just object references)
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Stream of auth state changes
  /// Subscribe once, get updates on login/logout - O(1) per event
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Get current user (synchronous, no network call)
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  /// Network call: O(1) time, O(1) space
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Map Firebase errors to user-friendly messages
      throw _mapAuthException(e);
    }
  }

  /// Create new user with email and password
  /// Network call: O(1) time, O(1) space
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Sign out current user
  /// Network call: O(1)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Map Firebase auth exceptions to readable error messages
  /// This keeps error handling logic in one place
  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}

