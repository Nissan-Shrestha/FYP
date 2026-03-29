import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/constants.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:http/http.dart' as http;

class OutfitService {
  static const String _baseApi = "${ApiConfig.serverBaseUrl}/api";

  static Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return await user.getIdToken() ?? (throw Exception("Could not get ID token"));
  }

  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _getIdToken();
    return {
      "Authorization": "Bearer $token",
      if (json) "Content-Type": "application/json",
    };
  }

  static Future<List<OutfitModel>> fetchOutfits() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseApi/outfits/"),
        headers: await _authHeaders(json: false),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => OutfitModel.fromJson(json)).toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchExploreOutfits({
    int page = 1,
    String? occasion,
    String? season,
  }) async {
    try {
      String url = "$_baseApi/outfits/explore/?page=$page";
      if (occasion != null && occasion.isNotEmpty) url += "&occasion=$occasion";
      if (season != null && season.isNotEmpty) url += "&season=$season";

      final response = await http.get(
        Uri.parse(url),
        headers: await _authHeaders(json: false),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data["results"];
        return {
          "results": results.map((json) => OutfitModel.fromJson(json)).toList(),
          "has_more": data["has_more"] as bool? ?? false,
        };
      }
    } catch (_) {
      return {"results": <OutfitModel>[], "has_more": false};
    }
    return {"results": <OutfitModel>[], "has_more": false};
  }

  static Future<Map<String, dynamic>?> toggleSaveOutfit(int outfitId) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseApi/outfits/$outfitId/toggle_save/"),
        headers: await _authHeaders(json: false),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<List<OutfitModel>> fetchSavedOutfits() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseApi/outfits/saved/"),
        headers: await _authHeaders(json: false),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => OutfitModel.fromJson(json)).toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  static Future<OutfitModel> createOutfit({
    required String name,
    String? occasion,
    required List<int> itemIds,
    bool isPublic = false,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseApi/outfits/"),
      headers: await _authHeaders(),
      body: jsonEncode({
        "name": name,
        "occasion": occasion,
        "item_ids": itemIds,
        "is_public": isPublic,
      }),
    );
    if (response.statusCode == 201) {
      return OutfitModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create outfit");
  }

  static Future<OutfitModel> updateOutfit(
    int outfitId, {
    String? name,
    String? occasion,
    List<int>? itemIds,
    bool? isPublic,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body["name"] = name;
    if (occasion != null) body["occasion"] = occasion;
    if (itemIds != null) body["item_ids"] = itemIds;
    if (isPublic != null) body["is_public"] = isPublic;

    final response = await http.patch(
      Uri.parse("$_baseApi/outfits/$outfitId/"),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return OutfitModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to update outfit");
  }

  static Future<void> deleteOutfit(int outfitId) async {
    final response = await http.delete(
      Uri.parse("$_baseApi/outfits/$outfitId/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode != 204) {
      throw Exception("Failed to delete outfit");
    }
  }
}
