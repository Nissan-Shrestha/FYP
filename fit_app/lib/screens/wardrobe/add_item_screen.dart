import 'dart:io';

import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  String itemName = "Enter item name";
  String season = "Choose the season";
  String occasion = "Choose the occasion";
  String category = "Choose the category";
  String size = "Choose the size";
  String material = "Choose the material";
  String brand = "Enter the brand";
  String purchase = "Add purchase info (optional)";
  String? _purchaseStore;
  double? _purchasePrice;
  DateTime? _purchaseDate;

  Future<void> _saveItem() async {
    final authVM = context.read<AuthViewmodel>();
    final wardrobeVM = context.read<WardrobeViewmodel>();
    final firebaseUid = authVM.profile?.firebaseUid;

    if (firebaseUid == null) {
      _showMessage("User not found. Please log in again.");
      return;
    }

    final cleanName = _valueOrEmpty(itemName, "Enter item name");
    if (cleanName.isEmpty) {
      _showMessage("Please add an item name.");
      return;
    }

    final requiredSelections = <String, String>{
      "Category": _valueOrEmpty(category, "Choose the category"),
      "Season": _valueOrEmpty(season, "Choose the season"),
      "Occasion": _valueOrEmpty(occasion, "Choose the occasion"),
      "Size": _valueOrEmpty(size, "Choose the size"),
      "Material": _valueOrEmpty(material, "Choose the material"),
      "Brand": _valueOrEmpty(brand, "Enter the brand"),
    };
    final missing = requiredSelections.entries
        .where((entry) => entry.value.isEmpty)
        .map((entry) => entry.key)
        .toList();
    if (missing.isNotEmpty) {
      _showMessage("Please fill: ${missing.join(", ")}");
      return;
    }

    if (_selectedImage == null) {
      _showMessage("Please add an item photo.");
      return;
    }

    final result = await wardrobeVM.createClothingItem(
      firebaseUid: firebaseUid,
      name: cleanName,
      category: _valueOrEmpty(category, "Choose the category"),
      season: _valueOrEmpty(season, "Choose the season"),
      occasion: _valueOrEmpty(occasion, "Choose the occasion"),
      size: _valueOrEmpty(size, "Choose the size"),
      material: _valueOrEmpty(material, "Choose the material"),
      brand: requiredSelections["Brand"]!,
      purchaseStore: _purchaseStore,
      purchasePrice: _purchasePrice,
      purchaseDate: _purchaseDate,
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (result != null) {
      _showMessage("Item saved");
      Navigator.pop(context);
      return;
    }

    _showMessage(wardrobeVM.error ?? "Failed to save item");
  }

  String _valueOrEmpty(String value, String placeholder) {
    return value == placeholder ? "" : value.trim();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: "Crop Item Photo",
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: "Crop Item Photo",
          ),
        ],
      );
      if (cropped == null) return;

      setState(() {
        _selectedImage = File(cropped.path);
      });
    } catch (e) {
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
                  "Add Item Photo",
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
                if (_selectedImage != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Remove Photo"),
                    onTap: () {
                      setState(() => _selectedImage = null);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeVM = context.watch<WardrobeViewmodel>();

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
                    color: Colors.black.withValues(alpha: 0.08),
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
          "Add Item",
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            size: 42,
                            color: Colors.black45,
                          ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                child: Column(
                  children: [
                    _FieldRow(
                      label: "Name",
                      value: itemName,
                      onTap: () => _openInputSheet(
                        title: "Item Name",
                        hint: "e.g. Blue Denim Jacket",
                        onApplied: (value) => setState(
                          () => itemName = value.isEmpty ? itemName : value,
                        ),
                      ),
                    ),
                    _FieldRow(
                      label: "Season",
                      value: season,
                      onTap: () => _openPickerSheet(
                        title: "Select Season",
                        subtitle: "Placeholder options for seasonal grouping",
                        options: const [
                          "Summer",
                          "Winter",
                          "Monsoon",
                          "All Season",
                        ],
                        onSelected: (value) => setState(() => season = value),
                      ),
                    ),
                    _FieldRow(
                      label: "Occasion",
                      value: occasion,
                      onTap: () => _openPickerSheet(
                        title: "Select Occasion",
                        subtitle: "Placeholder options for where you wear this",
                        options: const ["Casual", "Office", "Party", "Workout"],
                        onSelected: (value) => setState(() => occasion = value),
                      ),
                    ),
                    _FieldRow(
                      label: "Category",
                      value: category,
                      onTap: () => _openPickerSheet(
                        title: "Select Category",
                        subtitle: "Placeholder clothing categories",
                        options: const [
                          "Top",
                          "Bottom",
                          "Outerwear",
                          "Footwear",
                        ],
                        onSelected: (value) => setState(() => category = value),
                      ),
                    ),
                    _FieldRow(
                      label: "Size",
                      value: size,
                      onTap: () => _openPickerSheet(
                        title: "Select Size",
                        subtitle: "Placeholder sizes",
                        options: const ["XS", "S", "M", "L", "XL"],
                        onSelected: (value) => setState(() => size = value),
                      ),
                    ),
                    _FieldRow(
                      label: "Material",
                      value: material,
                      onTap: () => _openPickerSheet(
                        title: "Select Material",
                        subtitle: "Placeholder fabric materials",
                        options: const [
                          "Cotton",
                          "Linen",
                          "Denim",
                          "Polyester",
                        ],
                        onSelected: (value) => setState(() => material = value),
                      ),
                    ),
                    _FieldRow(
                      label: "Brand",
                      value: brand,
                      onTap: () => _openInputSheet(
                        title: "Brand",
                        hint: "Placeholder brand input",
                        onApplied: (value) => setState(
                          () => brand = value.isEmpty ? brand : value,
                        ),
                      ),
                    ),
                    _FieldRow(
                      label: "Purchase",
                      value: purchase,
                      onTap: () => _openPurchaseSheet(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: wardrobeVM.isSubmitting ? null : _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0AAE00),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          wardrobeVM.isSubmitting ? "Saving..." : "Save",
                          style: GoogleFonts.caveat(
                            fontSize: 24,
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
    required String subtitle,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
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
                  title,
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 14),
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
        );
      },
    );
  }

  Future<void> _openInputSheet({
    required String title,
    required String hint,
    required ValueChanged<String> onApplied,
  }) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
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
                    onApplied(controller.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ),
            ],
          ),
        );
      },
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
          builder: (context, setSheetState) {
            return Padding(
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
                  const SizedBox(height: 8),
                  Text(
                    "Add store, price or purchase date if you want to track it",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
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
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text("Enter a valid price"),
                                ),
                              );
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
            );
          },
        );
      },
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FieldRow({
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
        borderRadius: BorderRadius.circular(8),
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
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

