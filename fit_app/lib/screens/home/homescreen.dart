import 'package:fit_app/constants.dart';
import 'package:fit_app/screens/notifications/notification_screen.dart';
import 'package:fit_app/screens/schedule/schedule_screen.dart';
import 'package:fit_app/viewmodels/weather_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fit_app/viewmodels/auth_viewmodel.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherViewmodel>().fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50),

            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Consumer<AuthViewmodel>(
                    builder: (context, authVM, _) {
                      final username = authVM.profile?.username ?? "User";

                      return Text(
                        "Hello ${capitalize(username)}",
                        style: GoogleFonts.caveat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationScreen()),
                    );
                  },
                  child: Icon(Icons.notifications_outlined),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ScheduleScreen()),
                    );
                  },
                  child: Icon(Icons.calendar_month),
                ),
              ],
            ),
            SizedBox(height: 40),
            Consumer<WeatherViewmodel>(
              builder: (context, weatherVM, _) {
                return Container(
                  height: 105,
                  width: double.maxFinite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF8EC5FC),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: Offset(2, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: _buildWeatherContent(weatherVM),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              "Outfit Suggestions",
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              width: double.maxFinite,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: Offset(3, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                    ),
                    Text("This is just a place holder"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Recently Added Items",
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Your Personal Stylist",
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Stack(
                      children: [
                        SizedBox(
                          height: 200,
                          width: double.maxFinite,
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Text(
                                "Personal Stylist",
                                style: GoogleFonts.caveat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Container(
                                  width: double.maxFinite,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Container(
                                  width: double.maxFinite,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.cancel),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hey its your stylist"),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent(WeatherViewmodel weatherVM) {
    if (weatherVM.isLoading && weatherVM.weather == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (weatherVM.error != null && weatherVM.weather == null) {
      return Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              weatherVM.error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: () => weatherVM.fetchWeather(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      );
    }

    final weather = weatherVM.weather;
    if (weather == null) {
      return Row(
        children: [
          const Icon(Icons.wb_cloudy_outlined, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Weather unavailable",
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => weatherVM.fetchWeather(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      );
    }

    return Row(
      children: [
        Image.network(
          "https://openweathermap.org/img/wn/${weather.icon}@2x.png",
          width: 56,
          height: 56,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.cloud, color: Colors.white, size: 40),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weather.cityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                weather.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${weather.temperature.toStringAsFixed(1)}\u00B0C",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            if (weatherVM.isLoading)
              const Text(
                "Updating...",
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
      ],
    );
  }
}
