import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: Center(
        child: Text("Statistics Page", style: GoogleFonts.caveat(fontSize: 24)),
      ),
    );
  }
}
