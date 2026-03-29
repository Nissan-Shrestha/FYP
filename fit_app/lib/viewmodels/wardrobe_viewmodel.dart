import 'dart:io';

import 'package:fit_app/models/WardrobeModel.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/models/clothing_option_model.dart';
import 'package:fit_app/services/wardrobe_service.dart';
import 'package:flutter/material.dart';

class WardrobeViewmodel extends ChangeNotifier {
  List<WardrobeModel> wardrobes = [];
  List<ClothingItemModel> clothingItems = [];
  List<ClothingItemModel> selectedWardrobeItems = [];
  Map<int, List<ClothingItemModel>> wardrobePreviewItems = {};
  List<ClothingOptionModel> clothingOptions = [];

  bool isLoadingWardrobes = false;
  bool isLoadingClothingItems = false;
  bool isLoadingSelectedWardrobeItems = false;
  bool isLoadingWardrobePreviews = false;
  bool isLoadingOptions = false;
  bool isSubmitting = false;

  String? error;

  Future<void> fetchClothingOptions() async {
    try {
      isLoadingOptions = true;
      error = null;
      notifyListeners();

      clothingOptions = await WardrobeService.fetchClothingOptions();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingOptions = false;
      notifyListeners();
    }
  }

  List<String> getOptionsByType(String type) {
    return clothingOptions
        .where((o) => o.type == type)
        .map((o) => o.name)
        .toList();
  }

  Future<void> fetchWardrobes() async {
    try {
      isLoadingWardrobes = true;
      error = null;
      notifyListeners();

      wardrobes = await WardrobeService.fetchWardrobes();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingWardrobes = false;
      notifyListeners();
    }
  }

  Future<void> fetchClothingItems() async {
    try {
      isLoadingClothingItems = true;
      error = null;
      notifyListeners();

      clothingItems = await WardrobeService.fetchClothingItems();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingClothingItems = false;
      notifyListeners();
    }
  }

  Future<void> fetchItemsForWardrobe({
    required int wardrobeId,
  }) async {
    try {
      isLoadingSelectedWardrobeItems = true;
      error = null;
      notifyListeners();

      selectedWardrobeItems = await WardrobeService.fetchWardrobeItems(
        wardrobeId: wardrobeId,
      );
      wardrobePreviewItems[wardrobeId] = selectedWardrobeItems.take(4).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingSelectedWardrobeItems = false;
      notifyListeners();
    }
  }

  Future<void> fetchWardrobePreviews({int previewLimit = 4}) async {
    try {
      isLoadingWardrobePreviews = true;
      notifyListeners();

      final previewMap = <int, List<ClothingItemModel>>{};
      for (final wardrobe in wardrobes) {
        try {
          final items = await WardrobeService.fetchWardrobeItems(
            wardrobeId: wardrobe.id,
          );
          previewMap[wardrobe.id] = items.take(previewLimit).toList();
        } catch (_) {
          previewMap[wardrobe.id] = const [];
        }
      }

      wardrobePreviewItems = previewMap;
    } finally {
      isLoadingWardrobePreviews = false;
      notifyListeners();
    }
  }

  Future<WardrobeModel?> createWardrobe({
    required String name,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      final wardrobe = await WardrobeService.createWardrobe(name: name);

      wardrobes = [...wardrobes, wardrobe]
        ..sort((a, b) {
          if (a.isDefault != b.isDefault) {
            return a.isDefault ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      wardrobePreviewItems[wardrobe.id] = const [];

      return wardrobe;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<WardrobeModel?> renameWardrobe({
    required int wardrobeId,
    required String name,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      final updated = await WardrobeService.renameWardrobe(
        wardrobeId: wardrobeId,
        name: name,
      );

      wardrobes =
          wardrobes.map((w) => w.id == wardrobeId ? updated : w).toList()
            ..sort((a, b) {
              if (a.isDefault != b.isDefault) {
                return a.isDefault ? -1 : 1;
              }
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

      return updated;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteWardrobe({
    required int wardrobeId,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      await WardrobeService.deleteWardrobe(wardrobeId: wardrobeId);

      wardrobes = wardrobes.where((w) => w.id != wardrobeId).toList();
      wardrobePreviewItems.remove(wardrobeId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<ClothingItemModel?> createClothingItem({
    required String name,
    String category = "",
    String season = "",
    String occasion = "",
    String size = "",
    String material = "",
    String brand = "",    double? purchasePrice,
    File? imageFile,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      final item = await WardrobeService.createClothingItem(
        name: name,
        category: category,
        season: season,
        occasion: occasion,
        size: size,
        material: material,
        brand: brand,
        purchasePrice: purchasePrice,
        imageFile: imageFile,
      );

      clothingItems = [item, ...clothingItems];

      // New items are auto-added to the default wardrobe by backend rule,
      // so update the local preview cache immediately for instant UI feedback.
      WardrobeModel? defaultWardrobe;
      for (final wardrobe in wardrobes) {
        if (wardrobe.isDefault) {
          defaultWardrobe = wardrobe;
          break;
        }
      }
      if (defaultWardrobe != null) {
        final existingPreview =
            wardrobePreviewItems[defaultWardrobe.id] ?? const [];
        wardrobePreviewItems[defaultWardrobe.id] = [
          item,
          ...existingPreview,
        ].take(4).toList();
      }

      return item;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> addItemToWardrobe({
    required int wardrobeId,
    required int itemId,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      await WardrobeService.addItemToWardrobe(
        wardrobeId: wardrobeId,
        itemId: itemId,
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> removeItemFromWardrobe({
    required int wardrobeId,
    required int itemId,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      await WardrobeService.removeItemFromWardrobe(
        wardrobeId: wardrobeId,
        itemId: itemId,
      );

      selectedWardrobeItems = selectedWardrobeItems
          .where((item) => item.id != itemId)
          .toList();
      wardrobePreviewItems.update(
        wardrobeId,
        (items) => items.where((item) => item.id != itemId).toList(),
        ifAbsent: () => const [],
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteClothingItem({
    required int itemId,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      await WardrobeService.deleteClothingItem(itemId: itemId);

      clothingItems = clothingItems.where((item) => item.id != itemId).toList();
      selectedWardrobeItems = selectedWardrobeItems
          .where((item) => item.id != itemId)
          .toList();
      wardrobePreviewItems = {
        for (final entry in wardrobePreviewItems.entries)
          entry.key: entry.value.where((item) => item.id != itemId).toList(),
      };
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<ClothingItemModel?> updateClothingItem({
    required int itemId,
    required String name,
    required String category,
    required String season,
    required String occasion,
    required String size,
    required String material,
    required String brand,
    double? purchasePrice,
    File? imageFile,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      final updated = await WardrobeService.updateClothingItem(
        itemId: itemId,
        name: name,
        category: category,
        season: season,
        occasion: occasion,
        size: size,
        material: material,
        brand: brand,
        purchasePrice: purchasePrice,
        imageFile: imageFile,
      );

      clothingItems = clothingItems
          .map((item) => item.id == itemId ? updated : item)
          .toList();
      selectedWardrobeItems = selectedWardrobeItems
          .map((item) => item.id == itemId ? updated : item)
          .toList();
      wardrobePreviewItems = {
        for (final entry in wardrobePreviewItems.entries)
          entry.key: entry.value
              .map((item) => item.id == itemId ? updated : item)
              .toList(),
      };
      return updated;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
