import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  //change this to ip address if testing on mobile
  //use 10.0.2.2 for emulators
  //192.168.1.73 ghar lo ethernet ko
  static String get serverBaseUrl => dotenv.env['SERVER_BASE_URL'] ?? "http://10.0.2.2:8000";
}

String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
