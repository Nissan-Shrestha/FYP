import 'dart:convert';
import 'dart:io';

import 'package:fit_app/constants.dart';
import 'package:fit_app/models/profile_model.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = "${ApiConfig.serverBaseUrl}/api/profile/";

  static Future<ProfileModel> getOrCreateProfile({
    required String firebaseUid,
    required String email,
    String? username,
  }) async {
    final Map<String, dynamic> body = {
      "firebase_uid": firebaseUid,
      "email": email,
    };

    //  only include username if not null
    if (username != null) {
      body["username"] = username;
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Profile error");
    }
  }

  static Future<ProfileModel> updateUsername({
    required String firebaseUid,
    required String newUsername,
  }) async {
    final response = await http.patch(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"firebase_uid": firebaseUid, "username": newUsername}),
    );

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update username");
    }
  }

  static Future<ProfileModel> uploadProfilePicture({
    required String firebaseUid,
    required File imageFile,
  }) async {
    var request = http.MultipartRequest('PATCH', Uri.parse(baseUrl));

    request.fields['firebase_uid'] = firebaseUid;

    request.files.add(
      await http.MultipartFile.fromPath('profile_picture', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return ProfileModel.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception("Image upload failed");
    }
  }
}
