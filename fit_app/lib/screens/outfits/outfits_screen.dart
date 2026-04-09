import 'package:fit_app/constants.dart';
import 'package:fit_app/models/outfit_model.dart';

import 'package:fit_app/screens/outfits/create_outfit_screen.dart';
import 'package:fit_app/screens/outfits/edit_outfit_screen.dart';
import 'package:fit_app/screens/outfits/outfit_detail_screen.dart';
import 'package:fit_app/screens/schedule/schedule_screen.dart';
import 'package:fit_app/screens/stylist/stylist_screen.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OutfitViewmodel>().fetchOutfits();
        context.read<OutfitViewmodel>().fetchSavedOutfits();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitVM = context.watch<OutfitViewmodel>();
    final outfits = outfitVM.outfits;

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          "Outfits",
          style: GoogleFonts.manrope(fontSize: 21.6, fontWeight: FontWeight.bold),
        ),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: () => outfitVM.fetchOutfits(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const SizedBox(height: 10),
                _buildOutfitSuggestion(),
                const SizedBox(height: 20),
                Text(
                  "Create an Outfit",
                  style: GoogleFonts.manrope(
                    fontSize: 17.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateOutfitScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
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
                          "Create new outfits",
                          style: GoogleFonts.manrope(fontSize: 15.3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "My Outfits",
                  style: GoogleFonts.manrope(
                    fontSize: 17.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (outfitVM.isLoading && outfits.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (outfits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No outfits created yet",
                        style: GoogleFonts.manrope(fontSize: 15.3),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 18,
                      childAspectRatio:
                          (MediaQuery.of(context).size.width / 2) / 310,
                    ),
                    itemCount: outfits.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _OutfitCard(outfit: outfits[index]);
                    },
                  ),
                const SizedBox(height: 30),
                Text(
                  "Saved Outfits",
                  style: GoogleFonts.manrope(
                    fontSize: 17.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (outfitVM.isLoadingSaved && outfitVM.savedOutfits.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (outfitVM.savedOutfits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No saved outfits yet",
                        style: GoogleFonts.manrope(
                          fontSize: 15.3,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 18,
                      childAspectRatio:
                          (MediaQuery.of(context).size.width / 2) / 310,
                    ),
                    itemCount: outfitVM.savedOutfits.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _OutfitCard(
                        outfit: outfitVM.savedOutfits[index],
                        readOnly: true,
                      );
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitSuggestion() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StylistScreen()),
        );
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF673AB7),
              const Color(0xFF673AB7).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF673AB7).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 140,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "AI POWERED",
                            style: GoogleFonts.manrope(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Your Personal\nAI Stylist",
                          style: GoogleFonts.manrope(
                            fontSize: 23.4,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Let AI pick the perfect outfit for any occasion or weather.",
                          style: GoogleFonts.manrope(
                            fontSize: 11.7,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "Try Now",
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF673AB7),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final bool readOnly;

  const _OutfitCard({required this.outfit, this.readOnly = false});

  void _showOptions(BuildContext context) {
    final outfitVM = context.read<OutfitViewmodel>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (readOnly) ...[
                ListTile(
                  leading: const Icon(Icons.bookmark_remove, color: Colors.red),
                  title: Text(
                    "Unsave Outfit",
                    style: GoogleFonts.manrope(
                      fontSize: 15.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Unsave Outfit"),
                        content: const Text(
                          "Are you sure you want to remove this outfit from your saved list?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              "Unsave",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await outfitVM.toggleSaveOutfit(outfit);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Outfit unsaved")),
                        );
                      }
                    }
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: Text(
                    "Edit Outfit",
                    style: GoogleFonts.manrope(
                      fontSize: 15.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditOutfitScreen(outfit: outfit),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    "Delete Outfit",
                    style: GoogleFonts.manrope(
                      fontSize: 15.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete Outfit"),
                        content: const Text(
                          "Are you sure you want to delete this outfit? This action cannot be undone.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await outfitVM.deleteOutfit(outfit.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Outfit deleted")),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get up to 4 preview images
    final previewItems = outfit.items.take(4).toList();
    final imageUrls = previewItems
        .map((item) => item.image)
        .whereType<String>()
        .map(
          (path) => path.startsWith("http")
              ? path
              : "${ApiConfig.serverBaseUrl}$path",
        )
        .toList();

    // Fill slots for 2x2 grid
    final imageSlots = List<String?>.generate(
      4,
      (index) => index < imageUrls.length ? imageUrls[index] : null,
    );

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OutfitDetailScreen(outfit: outfit, readOnly: readOnly),
          ),
        );

        if (result == true && context.mounted) {
          context.read<OutfitViewmodel>().fetchOutfits();
        }
      },
      onLongPress: () => _showOptions(context),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniPreviewBox(imageUrl: imageSlots[0]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniPreviewBox(imageUrl: imageSlots[1]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniPreviewBox(imageUrl: imageSlots[2]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniPreviewBox(imageUrl: imageSlots[3]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            capitalize(outfit.name),
            style: GoogleFonts.manrope(
              fontSize: 14.4,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "${outfit.items.length} item${outfit.items.length == 1 ? "" : "s"}",
            style: const TextStyle(fontSize: 9.9, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MiniPreviewBox extends StatelessWidget {
  final String? imageUrl;
  const _MiniPreviewBox({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.grey.shade300,
          child: imageUrl == null
              ? const SizedBox.shrink()
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}
