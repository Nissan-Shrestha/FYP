import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/models/UserModel.dart';

class AuthService {
  // create a firebase auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Signs up a new user using Firebase Authentication.
  ///
  /// This method creates a new user with the provided email and password,
  /// updates the Firebase user's displayName with the given username,
  /// and returns a [UserModel] containing uid, email, and username.
  ///
  /// Parameters:
  /// - [email] : The user's email address.
  /// - [password] : The user's chosen password.
  /// - [username] : The user's display name (stored in Firebase Auth displayName).
  ///
  /// Returns:
  /// - [UserModel] containing uid, email, and username if signup succeeds.
  ///
  /// Throws:
  /// - [FirebaseAuthException] if signup fails (e.g., weak password, email already in use)
  /// - [Exception] for any other unexpected error.
  Future<UserModel?> signUp(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User user = result.user!;

      await user.updateDisplayName(username);
      await user.reload();

      return UserModel.fromFirebaseUser(_auth.currentUser!);
    } catch (e) {
      throw e;
    }
  }

  /// Signs in an existing user with email and password.
  ///
  /// Returns a [UserModel] if login succeeds.
  /// Throws a [FirebaseAuthException] if login fails.
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return UserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      throw e;
    }
  }

  /// Signs out the currently logged-in user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Listens to authentication state changes.
  /// Emits a [UserModel] when logged in, and `null` when logged out.
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map((User? firebaseUser) {
      if (firebaseUser != null) {
        return UserModel.fromFirebaseUser(firebaseUser);
      } else {
        return null;
      }
    });
  }
}
