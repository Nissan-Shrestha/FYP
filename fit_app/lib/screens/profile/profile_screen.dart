import 'package:fit_app/constants.dart';
import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

  void _showEditUsernameSheet(BuildContext context, AuthViewmodel authVM) {
    final controller = TextEditingController(text: authVM.profile!.username);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Edit Username",
                  style: GoogleFonts.caveat(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter new username",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () async {
                    final newName = controller.text.trim();

                    if (newName.isNotEmpty) {
                      await authVM.updateUsername(newName);
                    }

                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xff00A300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Save",
                        style: GoogleFonts.caveat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfilePictureSheet(BuildContext context, AuthViewmodel authVM) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Update Profile Picture",
                style: GoogleFonts.caveat(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  authVM.updateProfilePicture(ImageSource.camera);
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  authVM.updateProfilePicture(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewmodel>(context);
    final profile = authVM.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            /// PROFILE PICTURE (TAPPABLE)
                            GestureDetector(
                              onTap: () =>
                                  _showProfilePictureSheet(context, authVM),

                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: const Color(0xff00A300),
                                backgroundImage: profile.profilePicture != null
                                    ? NetworkImage(
                                        "${ApiConfig.serverBaseUrl}${profile.profilePicture}",
                                      )
                                    : null,

                                child: profile.profilePicture == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 35,
                                      )
                                    : null,
                              ),
                            ),

                            const SizedBox(width: 15),

                            /// USERNAME + EMAIL
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        capitalize(profile.username),
                                        style: GoogleFonts.caveat(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      GestureDetector(
                                        onTap: () => _showEditUsernameSheet(
                                          context,
                                          authVM,
                                        ),
                                        child: const Icon(Icons.edit, size: 18),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    profile.email,
                                    style: GoogleFonts.caveat(fontSize: 16),
                                  ),
                                ],
                              ),
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
                            MaterialPageRoute(
                              builder: (_) => const PlanScreen(),
                            ),
                          );
                        },
                        child: _profileRow("My Plan", profile.plan),
                      ),

                      const Divider(height: 1),

                      /// WARDROBE
                      _profileRow(
                        "Wardrobe",
                        "${profile.wardrobeCount}/${profile.wardrobeLimit}",
                      ),

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

                      /// OUTFITS
                      _profileRow(
                        "My Outfits",
                        "${profile.outfitsCount}/${profile.outfitsLimit}",
                      ),

                      const Divider(height: 1),

                      /// CURRENCY
                      _profileRow("Currency", profile.currency),

                      const SizedBox(height: 20),

                      /// LOGOUT
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
