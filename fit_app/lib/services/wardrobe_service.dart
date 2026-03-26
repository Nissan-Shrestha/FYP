import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/constants.dart';
import 'package:fit_app/models/WardrobeModel.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/models/clothing_option_model.dart';
import 'package:http/http.dart' as http;

class WardrobeService {
  static const String _baseApi = "${ApiConfig.serverBaseUrl}/api";

  static Future<List<ClothingOptionModel>> fetchClothingOptions() async {
    final response = await http.get(
      Uri.parse("$_baseApi/admin/options/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => ClothingOptionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    // Note: The /admin/options/ endpoint might actually be reachable 
    // without admin check for mobile users in our updated logic.
    throw Exception("Failed to fetch clothing options");
  }


  /// Gets the Firebase ID token for the current user.
  static Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return await user.getIdToken() ?? (throw Exception("Could not get ID token"));
  }

  /// Returns headers with the Bearer token + optional Content-Type.
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _getIdToken();
    return {
      "Authorization": "Bearer $token",
      if (json) "Content-Type": "application/json",
    };
  }

  static Future<List<WardrobeModel>> fetchWardrobes() async {
    final response = await http.get(
      Uri.parse("$_baseApi/wardrobes/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => WardrobeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Failed to fetch wardrobes");
  }

  static Future<WardrobeModel> createWardrobe({
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseApi/wardrobes/"),
      headers: await _authHeaders(),
      body: jsonEncode({"name": name}),
    );
    if (response.statusCode == 201) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to create wardrobe");
  }

  static Future<WardrobeModel> renameWardrobe({
    required int wardrobeId,
    required String name,
  }) async {
    final response = await http.patch(
      Uri.parse("$_baseApi/wardrobes/$wardrobeId/"),
      headers: await _authHeaders(),
      body: jsonEncode({"name": name}),
    );
    if (response.statusCode == 200) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to rename wardrobe");
  }

  static Future<void> deleteWardrobe({
    required int wardrobeId,
  }) async {
    final response = await http.delete(
      Uri.parse("$_baseApi/wardrobes/$wardrobeId/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode == 204) return;
    throw Exception("Failed to delete wardrobe");
  }

  static Future<List<ClothingItemModel>> fetchClothingItems() async {
    final response = await http.get(
      Uri.parse("$_baseApi/clothing-items/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => ClothingItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Failed to fetch clothing items");
  }

  static Future<List<ClothingItemModel>> fetchWardrobeItems({
    required int wardrobeId,
  }) async {
    final response = await http.get(
      Uri.parse("$_baseApi/wardrobes/$wardrobeId/items/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => ClothingItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Failed to fetch wardrobe items");
  }

  static Future<ClothingItemModel> createClothingItem({
    required String name,
    String category = "",
    String season = "",
    String occasion = "",
    String size = "",
    String material = "",
    String brand = "",
    double? purchasePrice,
    File? imageFile,
  }) async {
    final token = await _getIdToken();
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$_baseApi/clothing-items/"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.fields["name"] = name;
    request.fields["category"] = category;
    request.fields["season"] = season;
    request.fields["occasion"] = occasion;
    request.fields["size"] = size;
    request.fields["material"] = material;
    request.fields["brand"] = brand;

    if (purchasePrice != null) {
      request.fields["purchase_price"] = purchasePrice.toStringAsFixed(2);
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 201) {
      return ClothingItemModel.fromJson(jsonDecode(responseBody));
    }
    throw Exception("Failed to create clothing item");
  }

  static Future<WardrobeModel> addItemToWardrobe({
    required int wardrobeId,
    required int itemId,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseApi/wardrobes/$wardrobeId/items/"),
      headers: await _authHeaders(),
      body: jsonEncode({"item_id": itemId}),
    );
    if (response.statusCode == 200) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to add item to wardrobe");
  }

  static Future<WardrobeModel> removeItemFromWardrobe({
    required int wardrobeId,
    required int itemId,
  }) async {
    final response = await http.delete(
      Uri.parse("$_baseApi/wardrobes/$wardrobeId/items/$itemId/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode == 200) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to remove item from wardrobe");
  }

  static Future<void> deleteClothingItem({
    required int itemId,
  }) async {
    final response = await http.delete(
      Uri.parse("$_baseApi/clothing-items/$itemId/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode == 204) return;
    throw Exception("Failed to delete clothing item");
  }

  static Future<ClothingItemModel> updateClothingItem({
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
    final token = await _getIdToken();
    final request = http.MultipartRequest(
      "PATCH",
      Uri.parse("$_baseApi/clothing-items/$itemId/"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.fields["name"] = name;
    request.fields["category"] = category;
    request.fields["season"] = season;
    request.fields["occasion"] = occasion;
    request.fields["size"] = size;
    request.fields["material"] = material;
    request.fields["brand"] = brand;
    request.fields["purchase_price"] =
        purchasePrice == null ? "" : purchasePrice.toStringAsFixed(2);

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) {
      return ClothingItemModel.fromJson(jsonDecode(body));
    }
    throw Exception("Failed to update clothing item");
  }

}
