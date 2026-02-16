import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      // TODO: connect to reset logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              const SizedBox(height: 150),

              /// LOGO
              SizedBox(
                height: 100,
                width: 100,
                child: Image.asset("assets/icons/fit logo.jpg"),
              ),

              const SizedBox(height: 25),

              /// DESCRIPTION
              Text(
                "Enter your email to receive a password reset link",
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 25),

              /// EMAIL FIELD
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  hintStyle: GoogleFonts.caveat(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) =>
                    (value == null || !value.contains('@'))
                        ? 'Enter a valid email'
                        : null,
              ),

              const SizedBox(height: 25),

              /// CONTINUE BUTTON
              GestureDetector(
                onTap: _continue,
                child: Container(
                  width: double.maxFinite,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: const Color(0xff00A300),
                  ),
                  child: Center(
                    child: Text(
                      "Continue",
                      style: GoogleFonts.caveat(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// BACK TO LOGIN
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  "Back to Login",
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
