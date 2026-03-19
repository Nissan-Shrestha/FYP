import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateWardrobeScreen extends StatefulWidget {
  const CreateWardrobeScreen({super.key});

  @override
  State<CreateWardrobeScreen> createState() => _CreateWardrobeScreenState();
}

class _CreateWardrobeScreenState extends State<CreateWardrobeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createWardrobe(BuildContext context) async {
    final wardrobeVM = context.read<WardrobeViewmodel>();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage(context, "Please enter a wardrobe name.");
      return;
    }

    final result = await wardrobeVM.createWardrobe(
      name: name,
    );

    if (!mounted) return;

    if (result != null) {
      _showMessage(context, "Wardrobe created");
      Navigator.pop(context);
      return;
    }

    _showMessage(context, wardrobeVM.error ?? "Failed to create wardrobe");
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeVM = context.watch<WardrobeViewmodel>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xffF2F2F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Create a Wardrobe",
                  style: GoogleFonts.caveat(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                "Closet Name",
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 42,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createWardrobe(context),
                  decoration: InputDecoration(
                    hintText: "Enter a name for the wardrobe",
                    hintStyle: GoogleFonts.caveat(fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: wardrobeVM.isSubmitting
                      ? null
                      : () => _createWardrobe(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff17A8F2),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    wardrobeVM.isSubmitting ? "Creating..." : "Create",
                    style: GoogleFonts.caveat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
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

