import 'dart:convert';
import 'dart:io';

import 'package:fit_app/constants.dart';
import 'package:fit_app/models/WardrobeModel.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:http/http.dart' as http;

class WardrobeService {
  static const String _baseApi = "${ApiConfig.serverBaseUrl}/api";

  static Future<List<WardrobeModel>> fetchWardrobes({
    required String firebaseUid,
  }) async {
    final uri = Uri.parse("$_baseApi/wardrobes/").replace(
      queryParameters: {"firebase_uid": firebaseUid},
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => WardrobeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception("Failed to fetch wardrobes");
  }

  static Future<WardrobeModel> createWardrobe({
    required String firebaseUid,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseApi/wardrobes/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"firebase_uid": firebaseUid, "name": name}),
    );

    if (response.statusCode == 201) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }

    throw Exception("Failed to create wardrobe");
  }

  static Future<WardrobeModel> renameWardrobe({
    required String firebaseUid,
    required int wardrobeId,
    required String name,
  }) async {
    final response = await http.patch(
      Uri.parse("$_baseApi/wardrobes/$wardrobeId/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"firebase_uid": firebaseUid, "name": name}),
    );

    if (response.statusCode == 200) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }

    throw Exception("Failed to rename wardrobe");
  }

  static Future<void> deleteWardrobe({
    required String firebaseUid,
    required int wardrobeId,
  }) async {
    final uri = Uri.parse("$_baseApi/wardrobes/$wardrobeId/").replace(
      queryParameters: {"firebase_uid": firebaseUid},
    );

    final response = await http.delete(uri);
    if (response.statusCode == 204) return;

    throw Exception("Failed to delete wardrobe");
  }

  static Future<List<ClothingItemModel>> fetchClothingItems({
    required String firebaseUid,
  }) async {
    final uri = Uri.parse("$_baseApi/clothing-items/").replace(
      queryParameters: {"firebase_uid": firebaseUid},
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (json) =>
                ClothingItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception("Failed to fetch clothing items");
  }

  static Future<List<ClothingItemModel>> fetchWardrobeItems({
    required String firebaseUid,
    required int wardrobeId,
  }) async {
    final uri = Uri.parse("$_baseApi/wardrobes/$wardrobeId/items/").replace(
      queryParameters: {"firebase_uid": firebaseUid},
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (json) =>
                ClothingItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception("Failed to fetch wardrobe items");
  }

  static Future<ClothingItemModel> createClothingItem({
    required String firebaseUid,
    required String name,
    String category = "",
    String season = "",
    String occasion = "",
    String size = "",
    String material = "",
    String brand = "",
    File? imageFile,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$_baseApi/clothing-items/"),
    );

    request.fields["firebase_uid"] = firebaseUid;
    request.fields["name"] = name;
    request.fields["category"] = category;
    request.fields["season"] = season;
    request.fields["occasion"] = occasion;
    request.fields["size"] = size;
    request.fields["material"] = material;
    request.fields["brand"] = brand;

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
    required String firebaseUid,
    required int wardrobeId,
    required int itemId,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseApi/wardrobes/$wardrobeId/items/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"firebase_uid": firebaseUid, "item_id": itemId}),
    );

    if (response.statusCode == 200) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }

    throw Exception("Failed to add item to wardrobe");
  }

  static Future<WardrobeModel> removeItemFromWardrobe({
    required String firebaseUid,
    required int wardrobeId,
    required int itemId,
  }) async {
    final uri = Uri.parse("$_baseApi/wardrobes/$wardrobeId/items/$itemId/").replace(
      queryParameters: {"firebase_uid": firebaseUid},
    );

    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      return WardrobeModel.fromJson(jsonDecode(response.body));
    }

    throw Exception("Failed to remove item from wardrobe");
  }

  static Future<void> deleteClothingItem({
    required String firebaseUid,
    required int itemId,
  }) async {
    final uri = Uri.parse("$_baseApi/clothing-items/$itemId/").replace(
      queryParameters: {"firebase_uid": firebaseUid},
    );

    final response = await http.delete(uri);
    if (response.statusCode == 204) {
      return;
    }

    throw Exception("Failed to delete clothing item");
  }

  static Future<ClothingItemModel> updateClothingItem({
    required String firebaseUid,
    required int itemId,
    required String name,
    required String category,
    required String season,
    required String occasion,
    required String size,
    required String material,
    required String brand,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest(
      "PATCH",
      Uri.parse("$_baseApi/clothing-items/$itemId/"),
    );

    request.fields["firebase_uid"] = firebaseUid;
    request.fields["name"] = name;
    request.fields["category"] = category;
    request.fields["season"] = season;
    request.fields["occasion"] = occasion;
    request.fields["size"] = size;
    request.fields["material"] = material;
    request.fields["brand"] = brand;

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
