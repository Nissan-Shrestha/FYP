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
    // Return empty list for now until backend is implemented
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
      // If endpoint doesn't exist yet, just return empty
      return [];
    }
    return [];
  }

  static Future<OutfitModel> createOutfit({
    required String name,
    String? occasion,
    required List<int> itemIds,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseApi/outfits/"),
      headers: await _authHeaders(),
      body: jsonEncode({
        "name": name,
        "occasion": occasion,
        "item_ids": itemIds,
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
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body["name"] = name;
    if (occasion != null) body["occasion"] = occasion;
    if (itemIds != null) body["item_ids"] = itemIds;

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
