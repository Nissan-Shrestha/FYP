import 'package:fit_app/constants.dart';
import 'package:fit_app/screens/wardrobe/clothing_item_detail_screen.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AllClothesScreen extends StatefulWidget {
  const AllClothesScreen({super.key});

  @override
  State<AllClothesScreen> createState() => _AllClothesScreenState();
}

class _AllClothesScreenState extends State<AllClothesScreen> {
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeViewmodel>().fetchClothingItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeVM = context.watch<WardrobeViewmodel>();
    final items = wardrobeVM.clothingItems.where((item) {
      if (_selectedCategory == "All") return true;
      return item.category.trim().toLowerCase() == _selectedCategory.trim().toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(
          "My Collection",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 21.6),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildFilters(wardrobeVM),
          Expanded(
            child: wardrobeVM.isLoadingClothingItems
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF673AB7)),
                  )
                : items.isEmpty
                ? _buildEmptyState()
                : _buildGrid(items),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WardrobeViewmodel vm) {
    // Dynamically get unique categories from all items
    final Set<String> uniqueCategories = {"All"};
    for (var item in vm.clothingItems) {
      if (item.category.trim().isNotEmpty) {
        uniqueCategories.add(capitalize(item.category.trim()));
      }
    }
    final categories = uniqueCategories.toList()..sort((a, b) => a == "All" ? -1 : (b == "All" ? 1 : a.compareTo(b)));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: const Color(0xFF673AB7),
                    labelStyle: GoogleFonts.manrope(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.7,
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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

  Widget _buildGrid(items) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final url = item.image == null
            ? null
            : (item.image!.startsWith("http")
                  ? item.image!
                  : "${ApiConfig.serverBaseUrl}${item.image!}");

        return Hero(
          tag: "item_${item.id}",
          child: GestureDetector(
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        url != null
                            ? Image.network(url, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade100,
                                child: Icon(
                                  Icons.checkroom,
                                  color: Colors.grey.shade300,
                                  size: 40,
                                ),
                              ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capitalize(item.name),
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.color ?? "Unknown Color",
                          style: GoogleFonts.manrope(
                            color: Colors.grey,
                            fontSize: 10.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No items found",
            style: GoogleFonts.manrope(
              fontSize: 16.2,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your filters or search",
            style: GoogleFonts.manrope(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
