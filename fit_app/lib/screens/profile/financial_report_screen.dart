import 'package:fit_app/constants.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  String sortBy = "CPW (High to Low)";
  late List<dynamic> filteredItems;

  @override
  void initState() {
    super.initState();
    _applySort();
  }

  void _applySort() {
    final wardrobeVM = context.read<WardrobeViewmodel>();

    setState(() {
      if (sortBy == "CPW (High to Low)") {
        filteredItems = wardrobeVM.getPricedItemsSortedByCPW(descending: true);
      } else if (sortBy == "CPW (Low to High)") {
        filteredItems = wardrobeVM.getPricedItemsSortedByCPW(descending: false);
      } else if (sortBy == "Most Expensive") {
        final items = List<ClothingItemModel>.from(
          wardrobeVM.clothingItems.where((i) => i.purchasePrice != null),
        );
        items.sort((a, b) => b.purchasePrice!.compareTo(a.purchasePrice!));
        filteredItems = items;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(
          "Full Financial Report",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildSortFilterBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final cpw =
                    item.purchasePrice! /
                    (item.wearCount > 0 ? item.wearCount : 1);

                return _buildReportItem(item, cpw);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Text(
            "Sort by:",
            style: GoogleFonts.manrope(
              fontSize: 12.6,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      "CPW (High to Low)",
                      "CPW (Low to High)",
                      "Most Expensive",
                    ].map((option) {
                      final isSelected = sortBy == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => sortBy = option);
                              _applySort();
                            }
                          },
                          selectedColor: const Color(
                            0xFF673AB7,
                          ).withValues(alpha: 0.1),
                          labelStyle: GoogleFonts.manrope(
                            fontSize: 10.8,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF673AB7)
                                : Colors.black87,
                          ),
                          backgroundColor: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF673AB7)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(dynamic item, double cpw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _buildThumbnail(item),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  "${item.category} • Worn ${item.wearCount}x",
                  style: GoogleFonts.manrope(
                    fontSize: 10.8,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${cpw.toStringAsFixed(2)}",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.4,
                  color: const Color(0xff0AAE00),
                ),
              ),
              Text(
                "per wear",
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(dynamic item) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: item.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.image!.startsWith("http")
                    ? item.image!
                    : "${ApiConfig.serverBaseUrl}${item.image!}",
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.checkroom, color: Colors.grey),
    );
  }
}
