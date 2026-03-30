import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_app/constants.dart';
import 'package:fit_app/models/schedule_model.dart';
import 'package:http/http.dart' as http;

class ScheduleService {
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

  static Future<List<ScheduleModel>> fetchSchedules({String? date}) async {
    try {
      String url = "$_baseApi/schedules/";
      if (date != null) url += "?date=$date";

      final response = await http.get(
        Uri.parse(url),
        headers: await _authHeaders(json: false),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ScheduleModel.fromJson(json)).toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  static Future<ScheduleModel> createSchedule({
    required String eventTitle,
    required DateTime dateTime,
    required int outfitId,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseApi/schedules/"),
      headers: await _authHeaders(),
      body: jsonEncode({
        "event_title": eventTitle,
        "date_time": dateTime.toIso8601String(),
        "outfit_id": outfitId,
      }),
    );
    if (response.statusCode == 201) {
      return ScheduleModel.fromJson(jsonDecode(response.body));
    }
    final errorData = jsonDecode(response.body);
    throw Exception(errorData["error"] ?? "Failed to create schedule");
  }

  static Future<void> deleteSchedule(int scheduleId) async {
    final response = await http.delete(
      Uri.parse("$_baseApi/schedules/$scheduleId/"),
      headers: await _authHeaders(json: false),
    );
    if (response.statusCode != 204) {
      throw Exception("Failed to delete schedule");
    }
  }
}
