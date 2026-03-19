class ApiConfig {
  //change this to ip address if testing on mobile
  static const String serverBaseUrl = "http://10.0.2.2:8000";
}

String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
