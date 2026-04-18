import 'package:fit_app/models/profile_model.dart';
import 'package:fit_app/services/auth_service.dart';
import 'package:fit_app/services/profile_services.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fit_app/main.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        await requestNotificationPermission();
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
        await requestNotificationPermission();
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

  Future<void> deleteProfilePicture() async {
    if (_profile == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final updatedProfile = await ProfileService.deleteProfilePicture();
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
      try {
        _profile = await ProfileService.getOrCreateProfile(
          email: user.email ?? "",
          username: null,
        );
        await requestNotificationPermission();
      } catch (e) {
        // Profile sync failed — user may have been deleted by admin
        debugPrint("Profile check failed, signing out: $e");
        await _authService.signOut();
        _profile = null;
      }
      notifyListeners();
    }
  }

  Future<void> requestNotificationPermission() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized || 
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Sync again to make sure fcm_token is sent if it wasn't available before
        await syncProfile();
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // Inform the user why they might want them
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text("Notifications disabled. You'll miss out on daily style reminders! 🔔"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      debugPrint("Error requesting notification permission: $e");
    }
  }

  Future<void> syncProfile() async {
    if (_profile == null) return;
    try {
      _profile = await ProfileService.getOrCreateProfile(
        email: _profile!.email,
        username: null,
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Profile Sync Error: $e");
    }
  }

  Future<void> updateProfile({String? bio, Map<String, dynamic>? socialLinks}) async {
    if (_profile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedProfile = await ProfileService.updateProfile(
        bio: bio,
        socialLinks: socialLinks,
      );

      _profile = updatedProfile;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> upgradeToPremium() async {
    if (_profile == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Create Payment Intent
      final data = await ProfileService.createPremiumPaymentIntent();
      final clientSecret = data['client_secret'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Antigravity Fit App',
          style: ThemeMode.light,
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Success! Wait a bit for the webhook to reach the server
      await Future.delayed(const Duration(seconds: 3));

      // 5. Sync profile to get the new status
      await syncProfile();
      return true;
    } on StripeException catch (e) {
      _error = e.error.localizedMessage ?? "Payment canceled.";
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> upgradeToPremiumKhalti(BuildContext context) async {
    if (_profile == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Initiate Khalti Payment on Backend
      final data = await ProfileService.initiateKhaltiPremiumPayment();
      final pidx = data['pidx'];

      if (pidx == null) {
        throw Exception("Failed to get payment identifier (pidx) from server.");
      }

      // 2. Setup SDK Config
      final config = KhaltiPayConfig(
        publicKey: dotenv.env['KHALTI_PUBLIC_KEY'] ?? "e5e792eafff94651ad5d43ee0ac36bbd",
        pidx: pidx,
        environment: Environment.test,
      );

      // 3. Start Khalti Payment
      final completer = Completer<bool>();
      
      final khaltiInit = await Khalti.init(
        payConfig: config,
        onPaymentResult: (result, k) {
          debugPrint("Khalti Premium Success: ${result.toString()}");
          if (!completer.isCompleted) completer.complete(true);
          k.close(context);
        },
        onMessage: (k, {description, statusCode, event, needsPaymentConfirmation}) {
          debugPrint("Khalti Premium Message: $description");
          if (!completer.isCompleted) completer.complete(false);
          _error = description?.toString();
          k.close(context);
        },
      );

      khaltiInit.open(context);
      
      final success = await completer.future;

      if (success) {
        // Success! Wait a bit for the server to update the Profile
        await Future.delayed(const Duration(seconds: 3));
        await syncProfile();
      }
      return success;

    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
