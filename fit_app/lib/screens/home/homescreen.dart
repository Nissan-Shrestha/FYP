import 'package:fit_app/constants.dart';
import 'package:fit_app/screens/outfits/explore_outfits_screen.dart';
import 'package:fit_app/screens/profile/statistics_screen.dart';
import 'package:fit_app/screens/schedule/schedule_screen.dart';
import 'package:fit_app/screens/stylist/stylist_screen.dart';
import 'package:fit_app/screens/wardrobe/add_item_screen.dart';
import 'package:fit_app/screens/wardrobe/all_clothes_screen.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
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
      if (!mounted) return;
      final weatherVM = context.read<WeatherViewmodel>();
      final wardrobeVM = context.read<WardrobeViewmodel>();
      final outfitVM = context.read<OutfitViewmodel>();

      weatherVM.fetchWeather();
      wardrobeVM.fetchWardrobes();
      wardrobeVM.fetchClothingItems();
      outfitVM.fetchExploreOutfits(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF673AB7);
    final authVM = context.watch<AuthViewmodel>();
    final wardrobeVM = context.watch<WardrobeViewmodel>();
    final weatherVM = context.watch<WeatherViewmodel>();

    final profile = authVM.profile;

    return Scaffold(
      backgroundColor: const Color(
        0xffF8F9FA,
      ), // Slightly lighter grey for a cleaner look
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final weatherVM = context.read<WeatherViewmodel>();
            final wardrobeVM = context.read<WardrobeViewmodel>();
            final outfitVM = context.read<OutfitViewmodel>();

            await weatherVM.fetchWeather();
            await wardrobeVM.fetchClothingItems();
            await outfitVM.fetchExploreOutfits(refresh: true);
          },
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 1. Header with Profile
                _buildHeader(profile),

                const SizedBox(height: 24),

                // 2. Weather Highlights (Simplified)
                _buildWeatherCard(weatherVM),

                const SizedBox(height: 28),

                // 3. Quick Actions
                _buildQuickActions(context),

                const SizedBox(height: 32),

                // 4. Recently Added (Real Data)
                _buildRecentItems(wardrobeVM),

                const SizedBox(height: 32),

                // 5. AI Stylist Banner
                _buildAIStylistCTA(context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic profile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good Morning,",
                style: GoogleFonts.manrope(
                  fontSize: 12.6,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                profile?.username != null
                    ? capitalize(profile!.username)
                    : "Stylish!",
                style: GoogleFonts.manrope(
                  fontSize: 19.4,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF673AB7).withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: profile?.fullProfilePictureUrl != null
                ? NetworkImage(profile!.fullProfilePictureUrl!)
                : null,
            child: profile?.profilePicture == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(WeatherViewmodel weatherVM) {
    final weather = weatherVM.weather;
    final isLoading = weatherVM.isLoading;
    final error = weatherVM.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF764ba2).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S VIBE",
                style: GoogleFonts.manrope(
                  fontSize: 9.7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 2.0,
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                GestureDetector(
                  onTap: () => weatherVM.fetchWeather(),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (error != null && weather == null)
            _buildWeatherError(error, weatherVM)
          else
            _buildWeatherMain(weather),
        ],
      ),
    );
  }

  Widget _buildWeatherError(String message, WeatherViewmodel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Location Unreachable",
          style: GoogleFonts.manrope(
            fontSize: 16.2,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Using fallback data (London). Swipe down to retry.",
          style: GoogleFonts.manrope(
            fontSize: 11.7,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherMain(dynamic weather) {
    return Row(
      children: [
        if (weather != null)
          Image.network(
            "https://openweathermap.org/img/wn/${weather.icon}@2x.png",
            width: 64,
            height: 64,
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather != null
                    ? "${weather.temperature.toStringAsFixed(0)}\u00B0C"
                    : "--\u00B0C",
                style: GoogleFonts.manrope(
                  fontSize: 29.2,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              Text(
                weather != null
                    ? "${weather.cityName} \u2022 ${capitalize(weather.description)}"
                    : "Fetching your style atmosphere...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 12.2,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionIcon(context, Icons.add_rounded, "Add", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        }),
        _actionIcon(context, Icons.explore_outlined, "Explore", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExploreOutfitsScreen()),
          );
        }),
        _actionIcon(context, Icons.calendar_today_rounded, "Schedule", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScheduleScreen()),
          );
        }),
        _actionIcon(context, Icons.analytics_outlined, "Stats", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          );
        }),
      ],
    );
  }

  Widget _actionIcon(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF673AB7), size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10.8,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItems(WardrobeViewmodel vm) {
    final items = vm.clothingItems.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recently Added",
              style: GoogleFonts.manrope(
                fontSize: 14.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllClothesScreen()),
                );
              },
              child: Text(
                "View All",
                style: GoogleFonts.manrope(
                  fontSize: 11.7,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF673AB7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (vm.isLoadingClothingItems && items.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey.shade300,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  "Your wardrobe is empty",
                  style: GoogleFonts.manrope(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final url = item.image == null
                    ? null
                    : (item.image!.startsWith("http")
                          ? item.image!
                          : "${ApiConfig.serverBaseUrl}${item.image!}");

                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: url != null
                        ? Image.network(url, fit: BoxFit.cover)
                        : const Icon(Icons.checkroom, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAIStylistCTA(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StylistScreen()),
        );
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF673AB7),
              const Color(0xFF673AB7).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF673AB7).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background element
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 140,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "AI POWERED",
                            style: GoogleFonts.manrope(
                              fontSize: 8.1,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Your Personal\nAI Stylist",
                          style: GoogleFonts.manrope(
                            fontSize: 21.1,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Let AI pick the perfect outfit for any occasion or weather.",
                          style: GoogleFonts.manrope(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "Try Now",
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF673AB7),
                              fontWeight: FontWeight.w800,
                              fontSize: 11.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
