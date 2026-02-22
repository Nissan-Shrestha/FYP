import 'package:fit_app/screens/notifications/notification_screen.dart';
import 'package:fit_app/screens/schedule/schedule_screen.dart';
import 'package:fit_app/screens/wardrobe/create_wardrobe_screen.dart';
import 'package:fit_app/screens/wardrobe/wardrobe_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          "Wardrobe",
          style: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              );
            },
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// ================= RECENTLY ADDED =================
              Text(
                "Recently Added Items",
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  /// ADD BUTTON
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add),
                  ),

                  const SizedBox(width: 15),

                  /// HORIZONTAL ITEMS
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    "https://images.unsplash.com/photo-1593030761757-71fae45fa0e7",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 45),

              /// ================= WARDROBE SECTION =================
              Text(
                "Wardrobe",
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: WardrobeCategoryCard(
                      title: "All clothes",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WardrobeViewScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: WardrobeCategoryCard(
                      title: "Summer Clothes",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WardrobeViewScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// ================= CREATE NEW WARDROBE =================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateWardrobeScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_box_outlined, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        "Create new wardrobe",
                        style: GoogleFonts.caveat(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              /// ================= ADD NEW ITEMS =================
              Text(
                "Add new items",
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      "Add new items",
                      style: GoogleFonts.caveat(fontSize: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= CATEGORY CARD WIDGET =================
class WardrobeCategoryCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const WardrobeCategoryCard({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 170,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Expanded(child: MiniBox()),
                      SizedBox(width: 10),
                      Expanded(child: MiniBox()),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: const [
                      Expanded(child: MiniBox()),
                      SizedBox(width: 10),
                      Expanded(child: MiniBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GoogleFonts.caveat(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// ================= MINI BOX =================
class MiniBox extends StatelessWidget {
  const MiniBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400, // keep grey background
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          "https://images.unsplash.com/photo-1593030761757-71fae45fa0e7",
          fit: BoxFit.cover, // fills inside the box
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
