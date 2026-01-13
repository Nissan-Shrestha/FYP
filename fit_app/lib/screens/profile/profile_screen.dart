import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, AuthViewmodel authVM) async {
    await authVM.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final _authVM = Provider.of<AuthViewmodel>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              "My Profile",
              style: GoogleFonts.caveat(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(radius: 25),
                    title: Text(
                      _authVM.user?.username.isNotEmpty == true
                          ? capitalize(_authVM.user!.username)
                          : "No Name",
                      style: GoogleFonts.caveat(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      _authVM.user?.email.isNotEmpty == true
                          ? _authVM.user!.email
                          : "No Email",
                      style: GoogleFonts.caveat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                  ),
                  const Divider(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("My Plan"), Text("Free")],
                    ),
                  ),
                  const Divider(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("Wardrobe"), Text("67/100")],
                    ),
                  ),
                  const Divider(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("Statistics"), Text("View")],
                    ),
                  ),
                  const Divider(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("My Outfits"), Text("Free")],
                    ),
                  ),
                  const Divider(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("Style Points"), Text("67000")],
                    ),
                  ),
                  const Divider(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("Currency"), Text("USD")],
                    ),
                  ),
                  const Divider(color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    child: GestureDetector(
                      onTap: () => _logout(context, _authVM),
                      child: Text(
                        "Logout",
                        style: GoogleFonts.caveat(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
