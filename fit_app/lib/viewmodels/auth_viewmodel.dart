import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? user;
  bool isLoading = false;
  String? error;

  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      UserCredential result =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      user = result.user;
      error = null;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      UserCredential result =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      user = result.user;
      error = null;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
