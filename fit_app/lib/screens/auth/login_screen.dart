import 'package:fit_app/screens/nav/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login(AuthViewmodel authVM) async {
    if (_formKey.currentState!.validate()) {
      await authVM.signIn(_emailController.text, _passwordController.text);
      if (authVM.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NavigationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewmodel>(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 150),
              SizedBox(
                height: 100,
                width: 100,
                child: Image.asset("assets/icons/fit logo.jpg"),
              ),
              SizedBox(height: 25),
              Text(
                "Enter your email and password to securely access your wardrobe",
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 25),

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
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              SizedBox(height: 25),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
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
                validator: (value) => (value == null || value.length < 6)
                    ? 'Password too short'
                    : null,
              ),
              SizedBox(height: 25),

              if (authVM.isLoading)
                const CircularProgressIndicator()
              else
                GestureDetector(
                  onTap: () => _login(authVM),
                  child: Container(
                    width: double.maxFinite,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: const Color(0xff00A300),
                    ),
                    child: Center(
                      child: Text(
                        "Login",
                        style: GoogleFonts.caveat(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              if (authVM.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    authVM.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              SizedBox(height: 25),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegistrationScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account?",
                    style: GoogleFonts.caveat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: " Sign up here",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
