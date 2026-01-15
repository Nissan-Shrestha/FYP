import 'dart:async';
import 'package:fit_app/screens/auth/login_screen.dart';
import 'package:fit_app/screens/nav/navigation_screen.dart';
import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait 2 seconds, then navigate based on auth state
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final auth = Provider.of<AuthViewmodel>(context, listen: false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => auth.user != null
              ? const NavigationScreen()
              : const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset("assets/icons/fit logo.jpg")),
    );
  }
}
