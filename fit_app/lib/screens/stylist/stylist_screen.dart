import 'package:fit_app/viewmodels/stylist_viewmodel.dart';
import '../../viewmodels/wardrobe_viewmodel.dart';
import 'package:fit_app/viewmodels/weather_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StylistScreen extends StatefulWidget {
  const StylistScreen({super.key});

  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen> {
  String selectedOccasion = "Casual";
  bool useAutoWeather = true;
  String selectedManualWeather = "Clear Sky";
  final List<String> occasions = [
    "Casual",
    "Work",
    "Party",
    "Date",
    "Gym",
    "Formal",
  ];

  @override
  void initState() {
    super.initState();
    // Fetch clothes, options and weather on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherViewmodel>().fetchWeather();
      context.read<WardrobeViewmodel>().fetchClothingOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final WeatherViewmodel weatherVM = context.watch<WeatherViewmodel>();
    final StylistViewmodel stylistVM = context.watch<StylistViewmodel>();
    final WardrobeViewmodel wardrobeVM = context.watch<WardrobeViewmodel>();

    String weatherContext = "";
    if (useAutoWeather) {
      weatherContext = weatherVM.weather != null
          ? "${weatherVM.weather!.temperature.toStringAsFixed(0)}°C, ${weatherVM.weather!.description}"
          : "Moderate";
    } else {
      weatherContext = selectedManualWeather;
    }

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        title: Text(
          "Personal Stylist",
          style: GoogleFonts.caveat(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WeatherViewmodel>().fetchWeather();
          context.read<WardrobeViewmodel>().fetchClothingOptions();
          context.read<StylistViewmodel>().reset();
        },
        color: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherSection(weatherVM, wardrobeVM),
              const SizedBox(height: 25),
              Text(
                "What's the occasion?",
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildOccasionSelector(),
              const SizedBox(height: 30),
              _buildActionArea(stylistVM, weatherContext),
              const SizedBox(height: 20),
              if (stylistVM.status == StylistStatus.success)
                _buildRecommendationView(stylistVM),
              if (stylistVM.status == StylistStatus.error)
                _buildErrorView(stylistVM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSection(
    WeatherViewmodel weatherVM,
    WardrobeViewmodel wardrobeVM,
  ) {
    final manualOptions = wardrobeVM.getOptionsByType("weather");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              useAutoWeather ? "Live Weather (Auto)" : "Manual Fashion Mode",
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: useAutoWeather,
              onChanged: (val) => setState(() => useAutoWeather = val),
              activeColor: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (useAutoWeather)
          _buildWeatherHeader(weatherVM)
        else
          _buildManualWeatherSelector(manualOptions),
      ],
    );
  }

  Widget _buildManualWeatherSelector(List<String> options) {
    if (options.isEmpty) {
      return const Center(child: Text("No manual weathers available."));
    }
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final w = options[index];
          final isActive = selectedManualWeather == w;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(w),
              selected: isActive,
              onSelected: (val) => setState(() => selectedManualWeather = w),
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherHeader(WeatherViewmodel weatherVM) {
    final weather = weatherVM.weather;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF764ba2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (weather != null)
            Image.network(
              "https://openweathermap.org/img/wn/${weather.icon}@2x.png",
              width: 60,
              height: 60,
            )
          else
            const Icon(Icons.wb_sunny, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather != null
                      ? "${weather.temperature.toStringAsFixed(1)}°C"
                      : "--°C",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weather != null
                      ? weather.description.toUpperCase()
                      : "FETCHING WEATHER...",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionSelector() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: occasions.length,
        itemBuilder: (context, index) {
          final occ = occasions[index];
          final isActive = selectedOccasion == occ;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(occ),
              selected: isActive,
              onSelected: (val) => setState(() => selectedOccasion = occ),
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionArea(StylistViewmodel stylistVM, String weatherContext) {
    return Center(
      child: ElevatedButton(
        onPressed: stylistVM.isLoading
            ? null
            : () => stylistVM.getRecommendation(
                occasion: selectedOccasion,
                weather: weatherContext,
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: stylistVM.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                  SizedBox(width: 10),
                  Text(
                    "Get Styled",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRecommendationView(StylistViewmodel stylistVM) {
    final items = stylistVM.recommendedItems ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stylistVM.lookName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              stylistVM.lookName!.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stylistVM.stylistTip ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: item.image != null
                          ? Image.network(item.image!, fit: BoxFit.contain)
                          : const Icon(Icons.checkroom),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseColor(item.color),
                                border: item.color.toLowerCase() == "white"
                                    ? Border.all(
                                        color: Colors.grey.shade400,
                                        width: 0.5,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.color,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorView(StylistViewmodel stylistVM) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            stylistVM.error ?? "Unknown error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorName) {
    const colorMap = {
      'Black': Colors.black,
      'White': Colors.white,
      'Grey': Colors.grey,
      'Light Grey': Color(0xFFD3D3D3),
      'Dark Grey': Color(0xFFA9A9A9),
      'Charcoal': Color(0xFF36454F),
      'Navy Blue': Color(0xFF000080),
      'Royal Blue': Color(0xFF4169E1),
      'Blue': Colors.blue,
      'Light Blue': Color(0xFFADD8E6),
      'Sky Blue': Color(0xFF87CEEB),
      'Red': Colors.red,
      'Dark Red': Color(0xFF8B0000),
      'Maroon': Color(0xFF800000),
      'Burgundy': Color(0xFF800020),
      'Green': Colors.green,
      'Olive Green': Color(0xFF808000),
      'Forest Green': Color(0xFF228B22),
      'Beige': Color(0xFFF5F5DC),
      'Brown': Colors.brown,
      'Dark Brown': Color(0xFF3D2B1F),
      'Camel': Color(0xFFC19A6B),
      'Tan': Color(0xFFD2B48C),
      'Yellow': Colors.yellow,
      'Mustard': Color(0xFFFFDB58),
      'Orange': Colors.orange,
      'Purple': Colors.purple,
      'Pink': Colors.pink,
      'Teal': Color(0xFF008080),
      'Gold': Color(0xFFFFD700),
      'Silver': Color(0xFFC0C0C0),
    };

    return colorMap[colorName] ?? Colors.transparent;
  }
}
