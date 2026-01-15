import 'package:fit_app/models/UserModel.dart';
import 'package:fit_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthViewmodel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to Firebase auth changes immediately on ViewModel creation
  // This ensures that the ViewModel always knows the current user,
  // even after the app restarts.
  AuthViewmodel() {
    _authService.user.listen((user) {
      _user = user;          // update the ViewModel's _user whenever Firebase state changes
      notifyListeners();     // rebuild UI whenever user state changes
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Firebase authStateChanges() will automatically update _user
      await _authService.signIn(email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {      
      await _authService.signUp(email, password, username);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
   
  }
}
