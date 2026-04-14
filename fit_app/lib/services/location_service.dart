import 'package:fit_app/main.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied.");
      }

      // Try to get actual position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Medium is usually faster and enough for weather
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 10)); // Increased timeout
    } catch (e) {
      // UNIVERSAL FALLBACK: Try last known first (it's often accurate enough for weather)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }

      // Inform the user ONLY if we actually have to fall back to London
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("GPS unavailable. Showing weather for London 🇬🇧"),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
        )
      );

      return Position(
        latitude: 51.5074,
        longitude: -0.1278,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }
}
