import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/services/outfit_service.dart';
import 'package:flutter/material.dart';

class OutfitViewmodel extends ChangeNotifier {
  List<OutfitModel> outfits = [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? error;

  Future<void> fetchOutfits() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      outfits = await OutfitService.fetchOutfits();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<OutfitModel?> createOutfit({
    required String name,
    String? occasion,
    required List<int> itemIds,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      final outfit = await OutfitService.createOutfit(
        name: name,
        occasion: occasion,
        itemIds: itemIds,
      );

      outfits = [outfit, ...outfits];
      return outfit;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<OutfitModel?> updateOutfit(
    int outfitId, {
    String? name,
    String? occasion,
    List<int>? itemIds,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      final updatedOutfit = await OutfitService.updateOutfit(
        outfitId,
        name: name,
        occasion: occasion,
        itemIds: itemIds,
      );

      final index = outfits.indexWhere((o) => o.id == outfitId);
      if (index != -1) {
        outfits[index] = updatedOutfit;
      }
      return updatedOutfit;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOutfit(int outfitId) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      await OutfitService.deleteOutfit(outfitId);
      outfits = outfits.where((o) => o.id != outfitId).toList();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
