import 'package:fit_app/constants.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/screens/outfits/outfit_detail_screen.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ExploreOutfitsScreen extends StatefulWidget {
  const ExploreOutfitsScreen({super.key});

  @override
  State<ExploreOutfitsScreen> createState() => _ExploreOutfitsScreenState();
}

class _ExploreOutfitsScreenState extends State<ExploreOutfitsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OutfitViewmodel>().fetchExploreOutfits(refresh: true);
      context.read<OutfitViewmodel>().fetchExploreFilters();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<OutfitViewmodel>().fetchExploreOutfits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitVM = context.watch<OutfitViewmodel>();

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Explore",
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<OutfitViewmodel>().fetchExploreOutfits(refresh: true),
            icon: const Icon(Icons.refresh, color: Colors.black54),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: "All",
                  isSelected: outfitVM.selectedOccasion == null,
                  onTap: () => outfitVM.setFilters(occasion: null),
                ),
                ...outfitVM.availableOccasions.map((occ) => _FilterChip(
                      label: occ,
                      isSelected: outfitVM.selectedOccasion == occ,
                      onTap: () => outfitVM.setFilters(occasion: occ),
                    )),
              ],
            ),
          ),
        ),
      ),
      body: outfitVM.isLoadingExplore
          ? const Center(child: CircularProgressIndicator())
          : outfitVM.exploreOutfits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "No public outfits yet.",
                        style: GoogleFonts.caveat(
                          fontSize: 22,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Be the first to share your style!",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<OutfitViewmodel>().fetchExploreOutfits(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: outfitVM.exploreOutfits.length +
                        (outfitVM.isLoadingMoreExplore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == outfitVM.exploreOutfits.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final outfit = outfitVM.exploreOutfits[index];
                      return _ExploreOutfitCard(outfit: outfit);
                    },
                  ),
                ),
    );
  }
}

class _ExploreOutfitCard extends StatelessWidget {
  final OutfitModel outfit;

  const _ExploreOutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OutfitDetailScreen(outfit: outfit, readOnly: true),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + username + occasion badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xff0AAE00).withValues(alpha: 0.15),
                        backgroundImage: outfit.ownerProfilePicture != null
                            ? NetworkImage(
                                outfit.ownerProfilePicture!.startsWith("http")
                                    ? outfit.ownerProfilePicture!
                                    : "${ApiConfig.serverBaseUrl}${outfit.ownerProfilePicture!}",
                              )
                            : null,
                        child: outfit.ownerProfilePicture == null
                            ? Text(
                                (outfit.ownerUsername ?? "?").substring(0, 1).toUpperCase(),
                                style: GoogleFonts.caveat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff0AAE00),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outfit.ownerUsername ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              outfit.name,
                              style: GoogleFonts.caveat(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffEDF7ED),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xff0AAE00).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          outfit.occasion,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff0AAE00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        onSelected: (value) async {
                          if (value == 'report') {
                            final reason = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Report Outfit"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    "Inappropriate Content",
                                    "Spam",
                                    "Harassment",
                                    "Other"
                                  ].map((r) => ListTile(
                                        title: Text(r),
                                        onTap: () => Navigator.pop(context, r),
                                      )).toList(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                ],
                              ),
                            );

                            if (reason != null) {
                              if (!context.mounted) return;
                              final vm = context.read<OutfitViewmodel>();
                              final success = await vm.reportOutfit(outfit.id, reason);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success 
                                      ? "Report submitted. Thank you for helping our community!" 
                                      : "Failed to submit report. Please try again."),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: const [
                                Icon(Icons.report_gmailerrorred, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Report"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Items grid
                if (outfit.items.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: outfit.items.length > 8 ? 8 : outfit.items.length,
                      itemBuilder: (context, index) {
                        final item = outfit.items[index];
                        return _ExploreItemTile(item: item);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => context.read<OutfitViewmodel>().toggleSaveOutfit(outfit),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          outfit.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                          size: 20,
                          color: outfit.isSaved ? const Color(0xff0AAE00) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${outfit.savesCount}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: outfit.isSaved ? const Color(0xff0AAE00) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
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

class _ExploreItemTile extends StatelessWidget {
  final ClothingItemModel item;

  const _ExploreItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.image == null
        ? null
        : item.image!.startsWith("http")
            ? item.image!
            : "${ApiConfig.serverBaseUrl}${item.image!}";

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: const Color(0xffF5F5F5),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.checkroom, size: 24, color: Colors.grey),
              )
            : const Icon(Icons.checkroom, size: 24, color: Colors.grey),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xff0AAE00).withValues(alpha: 0.2),
        checkmarkColor: const Color(0xff0AAE00),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xff0AAE00) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xff0AAE00) : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
