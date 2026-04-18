import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/constants.dart';
import 'package:fit_app/models/featured_wardrobe_model.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:http/http.dart' as http;
import 'package:fit_app/services/session_guard.dart';

class OutfitService {
  static String get _baseApi => "${ApiConfig.serverBaseUrl}/api";

  static Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return await user.getIdToken() ??
        (throw Exception("Could not get ID token"));
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
      if (response.statusCode == 401) {
        checkForceLogout(response, null);
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchExploreOutfits({
    int page = 1,
    String? occasion,
  }) async {
    try {
      final queryParams = {
        "page": page.toString(),
        if (occasion != null && occasion.isNotEmpty) "occasion": occasion,
      };

      final uri = Uri.parse(
        "$_baseApi/outfits/explore/",
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
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

  static Future<List<String>> fetchExploreFilters() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseApi/outfits/explore/filters/"),
        headers: await _authHeaders(json: false),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return List<String>.from(data["occasions"] ?? []);
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

  static Future<bool> reportOutfit(int outfitId, String reason,
      {String? description}) async {
    final response = await http.post(
      Uri.parse("$_baseApi/outfits/report/"),
      headers: await _authHeaders(),
      body: jsonEncode({
        "outfit_id": outfitId,
        "reason": reason,
        if (description != null) "description": description,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> reportFeaturedWardrobe(int requestId, String reason,
      {String? description}) async {
    final response = await http.post(
      Uri.parse("$_baseApi/outfits/report/"),
      headers: await _authHeaders(),
      body: jsonEncode({
        "featured_request_id": requestId,
        "reason": reason,
        if (description != null) "description": description,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<List<CommunityFeaturedWardrobeModel>>
  fetchFeaturedWardrobes() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseApi/featured-wardrobes/discovery/"),
        headers: await _authHeaders(json: false),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => CommunityFeaturedWardrobeModel.fromJson(json))
            .toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }
}
