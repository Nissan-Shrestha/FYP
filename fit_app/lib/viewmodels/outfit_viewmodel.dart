import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/services/outfit_service.dart';
import 'package:flutter/material.dart';

class OutfitViewmodel extends ChangeNotifier {
  List<OutfitModel> outfits = [];
  List<OutfitModel> exploreOutfits = [];
  List<OutfitModel> savedOutfits = [];
  bool isLoading = false;
  bool isLoadingExplore = false;
  bool isLoadingSaved = false;
  bool isSubmitting = false;
  String? error;

  int currentExplorePage = 1;
  bool hasMoreExplore = true;
  bool isLoadingMoreExplore = false;

  String? selectedOccasion;
  String? selectedSeason;
  List<String> availableOccasions = [];

  Future<void> fetchExploreFilters() async {
    availableOccasions = await OutfitService.fetchExploreFilters();
    notifyListeners();
  }

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

  Future<void> fetchExploreOutfits({bool refresh = false}) async {
    if (refresh) {
      currentExplorePage = 1;
      hasMoreExplore = true;
      exploreOutfits = [];
    }

    if (!hasMoreExplore || isLoadingExplore || isLoadingMoreExplore) return;

    try {
      if (currentExplorePage == 1) {
        isLoadingExplore = true;
      } else {
        isLoadingMoreExplore = true;
      }
      error = null;
      notifyListeners();

      final response = await OutfitService.fetchExploreOutfits(
        page: currentExplorePage,
        occasion: selectedOccasion,
        season: selectedSeason,
      );
      final List<OutfitModel> results = response["results"];
      hasMoreExplore = response["has_more"];

      if (currentExplorePage == 1) {
        exploreOutfits = results;
      } else {
        exploreOutfits.addAll(results);
      }

      if (hasMoreExplore) {
        currentExplorePage++;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingExplore = false;
      isLoadingMoreExplore = false;
      notifyListeners();
    }
  }

  void setFilters({String? occasion, String? season}) {
    selectedOccasion = occasion;
    selectedSeason = season;
    fetchExploreOutfits(refresh: true);
  }

  Future<void> toggleSaveOutfit(OutfitModel outfit) async {
    final result = await OutfitService.toggleSaveOutfit(outfit.id);
    if (result != null) {
      // Update local state in all lists
      final isSaved = result["is_saved"] as bool;
      final savesCount = result["saves_count"] as int;

      void updateList(List<OutfitModel> list) {
        final index = list.indexWhere((o) => o.id == outfit.id);
        if (index != -1) {
          list[index] = list[index].copyWith(
            isSaved: isSaved,
            savesCount: savesCount,
          );
        }
      }

      updateList(outfits);
      updateList(exploreOutfits);
      
      if (isSaved) {
        if (!savedOutfits.any((o) => o.id == outfit.id)) {
          savedOutfits.insert(0, outfit.copyWith(isSaved: isSaved, savesCount: savesCount));
        }
      } else {
        savedOutfits.removeWhere((o) => o.id == outfit.id);
      }
      
      notifyListeners();
    }
  }

  Future<void> fetchSavedOutfits() async {
    try {
      isLoadingSaved = true;
      error = null;
      notifyListeners();

      savedOutfits = await OutfitService.fetchSavedOutfits();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingSaved = false;
      notifyListeners();
    }
  }

  Future<OutfitModel?> createOutfit({
    required String name,
    String? occasion,
    required List<int> itemIds,
    bool isPublic = false,
  }) async {
    try {
      isSubmitting = true;
      error = null;
      notifyListeners();

      final outfit = await OutfitService.createOutfit(
        name: name,
        occasion: occasion,
        itemIds: itemIds,
        isPublic: isPublic,
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
    bool? isPublic,
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
        isPublic: isPublic,
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
