import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/constants.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:http/http.dart' as http;

class StylistService {
  static String get _baseApi => "${ApiConfig.serverBaseUrl}/api";

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

  static Future<Map<String, dynamic>> fetchRecommendation({
    required String occasion,
    required String weather,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseApi/outfits/stylist/recommend/"),
        headers: await _authHeaders(),
        body: jsonEncode({
          "occasion": occasion,
          "weather": weather,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> itemsJson = data["items"];
        final List<ClothingItemModel> items = itemsJson
            .map((json) => ClothingItemModel.fromJson(json))
            .toList();
        
        return {
          "items": items,
          "stylist_tip": data["stylist_tip"] as String? ?? "Stay stylish!",
          "look_name": data["look_name"] as String? ?? "Curated Look",
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["error"] ?? "Failed to fetch recommendation");
      }
    } catch (e) {
      rethrow;
    }
  }
}
