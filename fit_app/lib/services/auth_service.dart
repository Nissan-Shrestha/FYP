import 'package:firebase_auth/firebase_auth.dart';
import '../models/UserModel.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;
    return UserModel(uid: user.uid, email: user.email ?? '');
  }

  Future<UserModel?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return _userFromFirebase(result.user);
  }

  Future<UserModel?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return _userFromFirebase(result.user);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
