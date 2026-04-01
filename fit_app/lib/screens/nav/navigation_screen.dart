import 'package:fit_app/screens/home/homescreen.dart';
import 'package:fit_app/screens/outfits/explore_outfits_screen.dart';
import 'package:fit_app/screens/outfits/outfits_screen.dart';
import 'package:fit_app/screens/profile/profile_screen.dart';
import 'package:fit_app/screens/wardrobe/wardrobe_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Homescreen(),
    WardrobeScreen(),
    OutfitsScreen(),
    ExploreOutfitsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (value) {
            setState(() {
              _currentIndex = value;
            });
          },
          unselectedItemColor: Colors.grey,
          selectedItemColor: Colors.black,
          showUnselectedLabels: true,
          unselectedLabelStyle: GoogleFonts.caveat(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          selectedLabelStyle: GoogleFonts.caveat(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom),
              label: "Wardrobe",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_module),
              label: "Outfits",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              label: "Explore",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
