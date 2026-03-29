import 'package:fit_app/constants.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EditOutfitScreen extends StatefulWidget {
  final OutfitModel outfit;

  const EditOutfitScreen({super.key, required this.outfit});

  @override
  State<EditOutfitScreen> createState() => _EditOutfitScreenState();
}

class _EditOutfitScreenState extends State<EditOutfitScreen> {
  late final TextEditingController _nameController;
  late String _selectedOccasion;
  late final List<int> _selectedItemIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.outfit.name);
    _selectedOccasion = widget.outfit.occasion;
    _selectedItemIds = widget.outfit.items.map((item) => item.id).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeViewmodel>().fetchClothingItems();
      context.read<WardrobeViewmodel>().fetchClothingOptions();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleItemSelection(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  Future<void> _saveOutfit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage("Please enter an outfit name.");
      return;
    }

    if (_selectedOccasion.isEmpty || _selectedOccasion == "Choose the occasion") {
      _showMessage("Please select an occasion for the outfit.");
      return;
    }

    if (_selectedItemIds.isEmpty) {
      _showMessage("Please select at least one item for the outfit.");
      return;
    }

    final outfitVM = context.read<OutfitViewmodel>();
    final result = await outfitVM.updateOutfit(
      widget.outfit.id,
      name: name,
      occasion: _selectedOccasion,
      itemIds: _selectedItemIds,
    );

    if (!mounted) return;

    if (result != null) {
      _showMessage("Outfit updated successfully!");
      Navigator.pop(context, result); // pass result back so previous screen can update
    } else {
      _showMessage(outfitVM.error ?? "Failed to update outfit");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeVM = context.watch<WardrobeViewmodel>();
    final outfitVM = context.watch<OutfitViewmodel>();

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
        centerTitle: true,
        title: Text(
          "Edit Outfit",
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          if (outfitVM.isSubmitting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveOutfit,
              child: Text(
                "Save",
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0AAE00),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Outfit Name",
                      labelStyle: GoogleFonts.caveat(fontSize: 18),
                      hintText: "e.g. Summer Brunch",
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _openOccasionPicker(wardrobeVM),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Text(
                            "Occasion",
                            style: GoogleFonts.caveat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _selectedOccasion,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_right, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  "Select Items (${_selectedItemIds.length})",
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: wardrobeVM.isLoadingClothingItems
                ? const Center(child: CircularProgressIndicator())
                : wardrobeVM.clothingItems.isEmpty
                    ? Center(
                        child: Text(
                          "No items in your wardrobe yet.",
                          style: GoogleFonts.caveat(fontSize: 18),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: wardrobeVM.clothingItems.length,
                        itemBuilder: (context, index) {
                          final item = wardrobeVM.clothingItems[index];
                          final isSelected = _selectedItemIds.contains(item.id);
                          return _ClothingItemSelectionTile(
                            item: item,
                            isSelected: isSelected,
                            onTap: () => _toggleItemSelection(item.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOccasionPicker(WardrobeViewmodel wardrobeVM) async {
    final occasions = wardrobeVM.getOptionsByType("occasion").isNotEmpty
        ? wardrobeVM.getOptionsByType("occasion")
        : const ["Casual", "Office", "Party", "Workout", "Formal"];

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Occasion",
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ...occasions.map(
                  (opt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(opt),
                    onTap: () {
                      setState(() => _selectedOccasion = opt);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClothingItemSelectionTile extends StatelessWidget {
  final ClothingItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClothingItemSelectionTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.image == null
        ? null
        : item.image!.startsWith("http")
            ? item.image!
            : "${ApiConfig.serverBaseUrl}${item.image!}";

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xff0AAE00) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.error),
                          )
                        : const Icon(Icons.checkroom, size: 32),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xff0AAE00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
