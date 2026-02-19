import 'package:fit_app/models/profile_model.dart';
import 'package:fit_app/services/auth_service.dart';
import 'package:fit_app/services/profile_services.dart';
import 'package:flutter/material.dart';

class AuthViewmodel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 🔥 SIGN UP
  Future<void> signUp(
      String email,
      String password,
      String username) async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUp(email, password);

      if (user != null) {
        _profile = await ProfileService.getOrCreateProfile(
          firebaseUid: user.uid,
          email: user.email ?? "",
          username: username, // 🔥 from textfield
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔥 SIGN IN
Future<void> signIn(String email, String password) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final user = await _authService.signIn(email, password);

    if (user != null) {
      _profile = await ProfileService.getOrCreateProfile(
        firebaseUid: user.uid,
        email: user.email ?? "",
        username: null,   // ✅ important
      );
    }
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


  Future<void> signOut() async {
    await _authService.signOut();
    _profile = null;
    notifyListeners();
  }
}
