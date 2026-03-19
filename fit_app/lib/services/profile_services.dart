import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/constants.dart';
import 'package:fit_app/models/profile_model.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = "${ApiConfig.serverBaseUrl}/api/profile/";

  /// Gets the Firebase ID token for the current user.
  /// Throws if the user is not logged in.
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

  static Future<ProfileModel> getOrCreateProfile({
    required String email,
    String? username,
  }) async {
    final Map<String, dynamic> body = {"email": email};
    if (username != null) body["username"] = username;

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Profile error: ${response.body}");
    }
  }

  static Future<ProfileModel> updateUsername({
    required String newUsername,
  }) async {
    final response = await http.patch(
      Uri.parse(baseUrl),
      headers: await _authHeaders(),
      body: jsonEncode({"username": newUsername}),
    );

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update username");
    }
  }

  static Future<ProfileModel> uploadProfilePicture({
    required File imageFile,
  }) async {
    final token = await _getIdToken();
    final request = http.MultipartRequest('PATCH', Uri.parse(baseUrl));

    request.headers["Authorization"] = "Bearer $token";
    request.files.add(
      await http.MultipartFile.fromPath('profile_picture', imageFile.path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return ProfileModel.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception("Image upload failed");
    }
  }
}
