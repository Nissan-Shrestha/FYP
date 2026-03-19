import 'package:fit_app/models/profile_model.dart';
import 'package:fit_app/services/auth_service.dart';
import 'package:fit_app/services/profile_services.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AuthViewmodel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  set profile(ProfileModel? value) {
    _profile = value;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  File? _localProfileImage;
  File? get localProfileImage => _localProfileImage;

  //  SIGN UP
  Future<void> signUp(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUp(email, password);

      if (user != null) {
        _profile = await ProfileService.getOrCreateProfile(
          email: user.email ?? "",
          username: username, // from textfield
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //  SIGN IN
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(email, password);

      if (user != null) {
        _profile = await ProfileService.getOrCreateProfile(
          email: user.email ?? "",
          username: null, // important
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

  Future<void> updateUsername(String newName) async {
    if (_profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedProfile = await ProfileService.updateUsername(
        newUsername: newName,
      );

      _profile = updatedProfile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture(ImageSource source) async {
    if (_profile == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      File imageFile = File(pickedFile.path);

      _isLoading = true;
      notifyListeners();

      final updatedProfile = await ProfileService.uploadProfilePicture(
        imageFile: imageFile,
      );

      _profile = updatedProfile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkCurrentUser() async {
    final user = _authService.currentUser;

    if (user != null) {
      _profile = await ProfileService.getOrCreateProfile(
        email: user.email ?? "",
        username: null,
      );
      notifyListeners();
    }
  }
}
