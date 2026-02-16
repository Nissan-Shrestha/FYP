import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import 'plan_screen.dart';
import 'statistics_screen.dart';

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
    final authVM = Provider.of<AuthViewmodel>(context);
    final user = authVM.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Text(
                "My Profile",
                style: GoogleFonts.caveat(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// USER INFO
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xff00A300),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.username.isNotEmpty == true
                                    ? capitalize(user!.username)
                                    : "No Name",
                                style: GoogleFonts.caveat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                user?.email.isNotEmpty == true
                                    ? user!.email
                                    : "No Email",
                                style: GoogleFonts.caveat(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    /// PLAN
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlanScreen()),
                        );
                      },
                      child: _profileRow("My Plan", "Free"),
                    ),

                    const Divider(height: 1),

                    /// WARDROBE
                    _profileRow("Wardrobe", "67/100"),

                    const Divider(height: 1),

                    /// STATISTICS
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StatisticsScreen(),
                          ),
                        );
                      },
                      child: _profileRow("Statistics", "View"),
                    ),

                    const Divider(height: 1),

                    /// OUTFITS UPDATED
                    _profileRow("My Outfits", "50/200"),

                    const Divider(height: 1),

                    /// STYLE POINTS
                    _profileRow("Style Points", "67000"),

                    const Divider(height: 1),

                    /// CURRENCY BOTTOM SHEET
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                          ),
                          builder: (_) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Select Currency",
                                    style: GoogleFonts.caveat(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ListTile(
                                    title: Text(
                                      "USD",
                                      style: GoogleFonts.caveat(fontSize: 18),
                                    ),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  ListTile(
                                    title: Text(
                                      "EUR",
                                      style: GoogleFonts.caveat(fontSize: 18),
                                    ),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  ListTile(
                                    title: Text(
                                      "NPR",
                                      style: GoogleFonts.caveat(fontSize: 18),
                                    ),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: _profileRow("Currency", "USD"),
                    ),

                    const SizedBox(height: 20),

                    /// LOGOUT BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => _logout(context, authVM),
                        child: Container(
                          height: 55,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Logout",
                              style: GoogleFonts.caveat(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.caveat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.caveat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
