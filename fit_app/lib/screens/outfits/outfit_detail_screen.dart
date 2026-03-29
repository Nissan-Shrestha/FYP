import 'package:fit_app/constants.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:fit_app/screens/wardrobe/clothing_item_detail_screen.dart'; // Add this line
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:fit_app/screens/outfits/edit_outfit_screen.dart';

class OutfitDetailScreen extends StatefulWidget {
  final OutfitModel outfit;
  final bool readOnly;

  const OutfitDetailScreen({super.key, required this.outfit, this.readOnly = false});

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  late OutfitModel outfit;

  @override
  void initState() {
    super.initState();
    outfit = widget.outfit;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Delete Outfit?",
            style: GoogleFonts.caveat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to delete '${outfit.name}'?",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final outfitVM = context.read<OutfitViewmodel>();
                final result = await outfitVM.deleteOutfit(outfit.id);

                if (!context.mounted) return;
                Navigator.pop(context); // Close dialog

                if (result) {
                  Navigator.pop(
                    context,
                    true,
                  ); // Close details screen & suggest refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Outfit deleted successfully"),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(outfitVM.error ?? "Delete failed")),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
        ),
        actions: [
          if (!widget.readOnly) ...[  
            IconButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditOutfitScreen(outfit: outfit),
                  ),
                );
                if (result != null && result is OutfitModel) {
                  setState(() {
                    outfit = result;
                  });
                }
              },
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            ),
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
          const SizedBox(width: 8),
        ],
        centerTitle: true,
        title: Text(
          capitalize(outfit.name),
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff0AAE00).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xff0AAE00),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    outfit.occasion,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0AAE00),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "${outfit.items.length} items",
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Items in this Outfit",
              style: GoogleFonts.caveat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 18,
                childAspectRatio: (MediaQuery.of(context).size.width / 2) / 325,
              ),
              itemCount: outfit.items.length,
              itemBuilder: (context, index) {
                final item = outfit.items[index];
                final imageUrl = item.image == null
                    ? null
                    : item.image!.startsWith("http")
                    ? item.image!
                    : "${ApiConfig.serverBaseUrl}${item.image!}";

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClothingItemDetailScreen(item: item),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Changed background color to white to distinguish it
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.error),
                                    )
                                  : const Icon(Icons.checkroom, size: 48),
                            ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capitalize(item.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (item.brand.isNotEmpty)
                              Text(
                                capitalize(item.brand),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              capitalize(item.category),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            if (item.purchasePrice != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "\$${item.purchasePrice!.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff0AAE00),
                                    fontWeight: FontWeight.bold,
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
            },
          ),
        ),
      ],
    ),
  );
}
}
