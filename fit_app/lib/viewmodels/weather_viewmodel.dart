import 'package:fit_app/models/weather_model.dart';
import 'package:fit_app/services/location_service.dart';
import 'package:fit_app/services/weather_service.dart';
import 'package:flutter/material.dart';

class WeatherViewmodel extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  WeatherModel? weather;
  bool isLoading = false;
  String? error;

  Future<void> fetchWeather() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final position = await _locationService.getCurrentLocation();
      weather = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
