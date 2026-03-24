import 'dart:io';

import 'package:fit_app/constants.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditClothingItemScreen extends StatefulWidget {
  final ClothingItemModel item;

  const EditClothingItemScreen({super.key, required this.item});

  @override
  State<EditClothingItemScreen> createState() => _EditClothingItemScreenState();
}

class _EditClothingItemScreenState extends State<EditClothingItemScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  late String itemName;
  late String season;
  late String occasion;
  late String category;
  late String size;
  late String material;
  late String brand;
  late String purchase;
  String? _purchaseStore;
  double? _purchasePrice;
  DateTime? _purchaseDate;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    itemName = item.name;
    season = item.season;
    occasion = item.occasion;
    category = item.category;
    size = item.size;
    material = item.material;
    brand = item.brand;
    _purchaseStore = item.purchaseStore.trim().isEmpty
        ? null
        : item.purchaseStore;
    _purchasePrice = item.purchasePrice;
    _purchaseDate = item.purchaseDate;
    purchase = _purchaseSummaryText();
  }

  Future<void> _saveChanges() async {
    final wardrobeVM = context.read<WardrobeViewmodel>();

    final values = <String, String>{
      "Name": itemName.trim(),
      "Category": category.trim(),
      "Season": season.trim(),
      "Occasion": occasion.trim(),
      "Size": size.trim(),
      "Material": material.trim(),
      "Brand": brand.trim(),
    };
    final missing = values.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();
    if (missing.isNotEmpty) {
      _showMessage("Please fill: ${missing.join(", ")}");
      return;
    }

    final result = await wardrobeVM.updateClothingItem(
      itemId: widget.item.id,
      name: values["Name"]!,
      category: values["Category"]!,
      season: values["Season"]!,
      occasion: values["Occasion"]!,
      size: values["Size"]!,
      material: values["Material"]!,
      brand: values["Brand"]!,
      purchaseStore: _purchaseStore,
      purchasePrice: _purchasePrice,
      purchaseDate: _purchaseDate,
      imageFile: _selectedImage,
    );

    if (!mounted) return;
    if (result != null) {
      _showMessage("Item updated");
      Navigator.pop(context, result);
      return;
    }
    _showMessage(wardrobeVM.error ?? "Failed to update item");
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        maxWidth: 1000,
        maxHeight: 1000,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: "Crop Item",
            toolbarColor: Colors.black,
            statusBarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xff0AAE00),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: "Crop Item",
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );
      if (cropped == null) return;

      setState(() => _selectedImage = File(cropped.path));
    } catch (_) {
      _showMessage("Failed to pick image");
    }
  }

  Future<void> _openImagePickerSheet() async {
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
                  "Update Item Photo",
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text("Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Choose from Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _purchaseSummaryText() {
    final parts = <String>[];
    if ((_purchaseStore ?? "").trim().isNotEmpty) {
      parts.add(_purchaseStore!.trim());
    }
    if (_purchasePrice != null) {
      parts.add("\$${_purchasePrice!.toStringAsFixed(2)}");
    }
    if (_purchaseDate != null) {
      parts.add(_formatDate(_purchaseDate!));
    }
    if (parts.isEmpty) return "Add purchase info (optional)";
    return parts.join(" • ");
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, "0");
    final m = date.month.toString().padLeft(2, "0");
    final d = date.day.toString().padLeft(2, "0");
    return "$y-$m-$d";
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeVM = context.watch<WardrobeViewmodel>();
    final existingImageUrl = widget.item.image == null
        ? null
        : widget.item.image!.startsWith("http")
        ? widget.item.image!
        : "${ApiConfig.serverBaseUrl}${widget.item.image!}";

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        centerTitle: true,
        title: Text(
          "Edit Item",
          style: GoogleFonts.caveat(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: wardrobeVM.isSubmitting ? null : _openImagePickerSheet,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xffD9D9D9),
                    borderRadius: BorderRadius.circular(16),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : existingImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(existingImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (_selectedImage == null && existingImageUrl == null)
                      ? const Center(
                          child: Icon(Icons.image_outlined, size: 40),
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Change Photo",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  children: [
                    _EditableFieldRow(
                      label: "Name",
                      value: itemName,
                      onTap: () => _openInputSheet(
                        title: "Item Name",
                        hint: "e.g. Blue Denim Jacket",
                        initialValue: itemName,
                        onApplied: (v) => setState(() => itemName = v),
                      ),
                    ),
                    _EditableFieldRow(
                      label: "Season",
                      value: season,
                      onTap: () => _openPickerSheet(
                        title: "Select Season",
                        options:
                            wardrobeVM.getOptionsByType("season").isNotEmpty
                            ? wardrobeVM.getOptionsByType("season")
                            : const [
                                "Summer",
                                "Winter",
                                "Monsoon",
                                "All Season",
                              ],
                        onSelected: (v) => setState(() => season = v),
                      ),
                    ),
                    _EditableFieldRow(
                      label: "Occasion",
                      value: occasion,
                      onTap: () => _openPickerSheet(
                        title: "Select Occasion",
                        options:
                            wardrobeVM.getOptionsByType("occasion").isNotEmpty
                            ? wardrobeVM.getOptionsByType("occasion")
                            : const ["Casual", "Office", "Party", "Workout"],
                        onSelected: (v) => setState(() => occasion = v),
                      ),
                    ),
                    _EditableFieldRow(
                      label: "Category",
                      value: category,
                      onTap: () => _openPickerSheet(
                        title: "Select Category",
                        options:
                            wardrobeVM.getOptionsByType("category").isNotEmpty
                            ? wardrobeVM.getOptionsByType("category")
                            : const ["Top", "Bottom", "Outerwear", "Footwear"],
                        onSelected: (v) => setState(() => category = v),
                      ),
                    ),
                    _EditableFieldRow(
                      label: "Size",
                      value: size,
                      onTap: () => _openPickerSheet(
                        title: "Select Size",
                        options: wardrobeVM.getOptionsByType("size").isNotEmpty
                            ? wardrobeVM.getOptionsByType("size")
                            : const ["XS", "S", "M", "L", "XL"],
                        onSelected: (v) => setState(() => size = v),
                      ),
                    ),
                    _EditableFieldRow(
                      label: "Material",
                      value: material,
                      onTap: () => _openPickerSheet(
                        title: "Select Material",
                        options:
                            wardrobeVM.getOptionsByType("material").isNotEmpty
                            ? wardrobeVM.getOptionsByType("material")
                            : const ["Cotton", "Linen", "Denim", "Polyester"],
                        onSelected: (v) => setState(() => material = v),
                      ),
                    ),
                    _EditableFieldRow(
                      label: "Brand",
                      value: brand,
                      onTap: () => _openInputSheet(
                        title: "Brand",
                        hint: "Brand",
                        initialValue: brand,
                        onApplied: (v) => setState(() => brand = v),
                      ),
                    ),
                    _EditableFieldRow(
                      label: "Purchase",
                      value: purchase,
                      onTap: _openPurchaseSheet,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: wardrobeVM.isSubmitting
                            ? null
                            : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0AAE00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          wardrobeVM.isSubmitting
                              ? "Saving..."
                              : "Save Changes",
                          style: GoogleFonts.caveat(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPickerSheet({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInputSheet({
    required String title,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onApplied,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.caveat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    onApplied(value);
                  }
                  Navigator.pop(context);
                },
                child: const Text("Apply"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPurchaseSheet() async {
    final storeController = TextEditingController(text: _purchaseStore ?? "");
    final priceController = TextEditingController(
      text: _purchasePrice == null ? "" : _purchasePrice!.toStringAsFixed(2),
    );
    DateTime? selectedDate = _purchaseDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Purchase Info (Optional)",
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: storeController,
                  decoration: InputDecoration(
                    hintText: "Store name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: "Price",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? "Select purchase date"
                        : "Purchase date: ${_formatDate(selectedDate!)}",
                  ),
                ),
                if (selectedDate != null)
                  TextButton(
                    onPressed: () => setSheetState(() => selectedDate = null),
                    child: const Text("Clear date"),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _purchaseStore = null;
                            _purchasePrice = null;
                            _purchaseDate = null;
                            purchase = _purchaseSummaryText();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Clear"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final rawPrice = priceController.text.trim();
                          final parsedPrice = rawPrice.isEmpty
                              ? null
                              : double.tryParse(rawPrice);
                          if (rawPrice.isNotEmpty && parsedPrice == null) {
                            _showMessage("Enter a valid price");
                            return;
                          }

                          setState(() {
                            final store = storeController.text.trim();
                            _purchaseStore = store.isEmpty ? null : store;
                            _purchasePrice = parsedPrice;
                            _purchaseDate = selectedDate;
                            purchase = _purchaseSummaryText();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditableFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _EditableFieldRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 86,
                child: Text(
                  label,
                  style: GoogleFonts.caveat(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
