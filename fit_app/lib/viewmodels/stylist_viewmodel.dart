import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/services/stylist_service.dart';
import 'package:flutter/material.dart';

enum StylistStatus { initial, loading, success, error }

class StylistViewmodel extends ChangeNotifier {
  List<ClothingItemModel>? recommendedItems;
  String? stylistTip;
  String? lookName;
  String? error;
  StylistStatus status = StylistStatus.initial;

  bool get isLoading => status == StylistStatus.loading;

  Future<void> getRecommendation({
    required String occasion,
    required String weather,
  }) async {
    try {
      status = StylistStatus.loading;
      error = null;
      notifyListeners();

      final result = await StylistService.fetchRecommendation(
        occasion: occasion,
        weather: weather,
      );

      recommendedItems = result["items"] as List<ClothingItemModel>;
      stylistTip = result["stylist_tip"] as String;
      lookName = result["look_name"] as String;
      status = StylistStatus.success;
    } catch (e) {
      error = e.toString().replaceAll("Exception: ", "");
      status = StylistStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Map<String, dynamic>? analysisData;
  bool isAnalyzing = false;

  Future<void> runAnalysis({String? stylePreference}) async {
    try {
      isAnalyzing = true;
      error = null;
      notifyListeners();

      final result = await StylistService.analyzeWardrobe(
        stylePreference: stylePreference,
      );
      analysisData = result;
      status = StylistStatus.success;
    } catch (e) {
      error = e.toString().replaceAll("Exception: ", "");
      status = StylistStatus.error;
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
  }

  void resetRecommendation() {
    recommendedItems = null;
    stylistTip = null;
    lookName = null;
    if (analysisData == null) {
      status = StylistStatus.initial;
    }
    notifyListeners();
  }

  void resetAnalysis() {
    analysisData = null;
    if (recommendedItems == null) {
      status = StylistStatus.initial;
    }
    notifyListeners();
  }

  void reset() {
    recommendedItems = null;
    stylistTip = null;
    lookName = null;
    analysisData = null;
    status = StylistStatus.initial;
    error = null;
    notifyListeners();
  }
}

