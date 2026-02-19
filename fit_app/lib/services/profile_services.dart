import 'dart:convert';

import 'package:fit_app/models/profile_model.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = "http://10.0.2.2:8000/api/profile/";

  static Future<ProfileModel> getOrCreateProfile({
  required String firebaseUid,
  required String email,
  String? username,
}) async {

  final Map<String, dynamic> body = {
    "firebase_uid": firebaseUid,
    "email": email,
  };

  // 🔥 only include username if not null
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

}
