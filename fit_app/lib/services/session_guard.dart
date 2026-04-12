import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fit_app/main.dart';
import 'package:fit_app/screens/auth/login_screen.dart';

/// Checks if an API response indicates the user session is invalid (401).
/// If so, signs out the user and navigates to the login screen.
/// Returns true if the session was invalidated (caller should stop processing).
bool checkForceLogout(http.Response response, BuildContext? ctx) {
  if (response.statusCode == 401) {
    _handleForceLogout();
    return true;
  }
  return false;
}

/// Force sign-out and show a message to the user.
void _handleForceLogout() async {
  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}

  // Show a message via the global scaffold messenger
  scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(
      content: Text("Your session has expired or your account was removed. Please log in again."),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 5),
    ),
  );

  // Navigate to login using the global navigator key
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
