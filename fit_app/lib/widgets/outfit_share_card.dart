import 'package:fit_app/constants.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OutfitShareCard extends StatelessWidget {
  final OutfitModel outfit;

  const OutfitShareCard({super.key, required this.outfit});

  @override
  Widget build(BuildContext context) {
    // Dynamic scaling based on item count
    final bool isLargeOutfit = outfit.items.length > 4;
    final int crossAxisCount = isLargeOutfit ? 3 : 2;
    final double itemFontSize = isLargeOutfit ? 8 : 10;
    final double headerFontSize = isLargeOutfit ? 18 : 22;

    return Container(
      width: 400,
      height: 550, // Fixed height for a predictable, shareable card
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  "assets/icons/fit logo.jpg",
                  width: isLargeOutfit ? 35 : 45,
                  height: isLargeOutfit ? 35 : 45,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.checkroom, size: 30),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      outfit.occasion.toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontSize: isLargeOutfit ? 8 : 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff0AAE00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Items Grid - Scales down as more items are added
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: outfit.items.length,
              itemBuilder: (context, index) {
                final item = outfit.items[index];
                final imageUrl = item.image == null
                    ? null
                    : item.image!.startsWith("http")
                    ? item.image!
                    : "${ApiConfig.serverBaseUrl}${item.image!}";

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffFDFDFD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: imageUrl != null
                              ? Image.network(imageUrl, fit: BoxFit.contain)
                              : const Icon(
                                  Icons.checkroom,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text(
                          item.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: itemFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Clean Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  "Curated with love inside Fit App",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  "YOUR PERSONAL WARDROBE COMPANION",
                  style: GoogleFonts.manrope(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
