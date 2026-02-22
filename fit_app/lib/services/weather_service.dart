import 'dart:convert';

import 'package:fit_app/models/weather_model.dart';

import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "2b780926c017c10e102b1cdbdedbb4c2";

  Future<WeatherModel> fetchWeather(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return WeatherModel.fromJson(data);
    } else {
      throw Exception("Failed to fetch weather");
    }
  }
}
