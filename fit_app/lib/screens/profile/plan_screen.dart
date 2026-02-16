import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Plan")),
      body: Center(
        child: Text("Plan Details", style: GoogleFonts.caveat(fontSize: 24)),
      ),
    );
  }
}
