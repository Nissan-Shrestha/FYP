import 'package:fit_app/viewmodels/stylist_viewmodel.dart';
import '../../viewmodels/wardrobe_viewmodel.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:fit_app/viewmodels/weather_viewmodel.dart';
import 'package:fit_app/screens/outfits/outfit_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../profile/plan_screen.dart';

class StylistScreen extends StatefulWidget {
  const StylistScreen({super.key});

  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen> {
  String selectedOccasion = "Casual";
  bool useAutoWeather = true;
  String selectedManualWeather = "Clear Sky";
  String selectedStylePreference = "Unisex";

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
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 21.6,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final weatherVM = context.read<WeatherViewmodel>();
          final wardrobeVM = context.read<WardrobeViewmodel>();
          final stylistVM = context.read<StylistViewmodel>();
          final authVM = context.read<AuthViewmodel>();

          await weatherVM.fetchWeather();
          await wardrobeVM.fetchClothingOptions();
          await authVM.syncProfile();
          stylistVM.reset();
        },
        color: const Color(0xFF673AB7),
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
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Influences recommended outfits only",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOccasionSelector(wardrobeVM),
              const SizedBox(height: 25),
              Text(
                "Style Preference",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Influences wardrobe analysis only",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              _buildStylePreferenceSelector(),
              const SizedBox(height: 30),
              _buildUsageIndicator(context),
              const SizedBox(height: 12),
              _buildActionArea(stylistVM, weatherContext),
              const SizedBox(height: 20),
              if (stylistVM.status == StylistStatus.success) ...[
                if (stylistVM.recommendedItems != null)
                  _buildRecommendationView(stylistVM),
                if (stylistVM.analysisData != null)
                  _buildAnalysisResult(stylistVM, stylistVM.analysisData!),
              ],
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
            Flexible(
              child: Text(
                useAutoWeather ? "Live Weather (Auto)" : "Manual Fashion Mode",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch(
              value: useAutoWeather,
              onChanged: (val) => setState(() => useAutoWeather = val),
              activeThumbColor: const Color(0xFF673AB7),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          "Influences recommended outfits only",
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
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
              selectedColor: const Color(0xFF673AB7),
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
                "LOCAL ATMOSPHERE",
                style: GoogleFonts.manrope(
                  fontSize: 9.9,
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
            _buildWeatherError(error)
          else
            _buildWeatherMain(weather),
        ],
      ),
    );
  }

  Widget _buildWeatherError(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Connection Issue",
          style: GoogleFonts.manrope(
            fontSize: 16.2,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Using style fallback. Tap refresh to retry.",
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
            width: 60,
            height: 60,
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_cloudy_rounded,
              color: Colors.white,
              size: 28,
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
                  fontSize: 28.8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              Text(
                weather != null
                    ? "${weather.cityName} \u2022 ${weather.description.toUpperCase()}"
                    : "PREPARING WEATHER DATA...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 11.7,
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

  Widget _buildStylePreferenceSelector() {
    final styles = ["Masculine", "Feminine", "Unisex", "Abstract"];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final style = styles[index];
          final isSelected = selectedStylePreference == style;
          return ChoiceChip(
            label: Text(style),
            selected: isSelected,
            onSelected: (val) {
              if (val) setState(() => selectedStylePreference = style);
            },
            selectedColor: const Color(0xFF673AB7).withValues(alpha: 0.2),
            labelStyle: GoogleFonts.manrope(
              color: isSelected ? const Color(0xFF673AB7) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12.6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF673AB7)
                    : Colors.grey.shade300,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildOccasionSelector(WardrobeViewmodel wardrobeVM) {
    final dynamicOccasions = wardrobeVM.getOptionsByType("occasion");

    // Fallback if DB hasn't loaded or is empty
    final list = dynamicOccasions.isNotEmpty
        ? dynamicOccasions
        : ["Casual", "Work", "Party", "Date", "Gym", "Formal"];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final occ = list[index];
          final isActive = selectedOccasion == occ;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(occ),
              selected: isActive,
              onSelected: (val) {
                if (val) {
                  setState(() => selectedOccasion = occ);
                }
              },
              selectedColor: const Color(0xFF673AB7),
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

  Widget _buildUsageIndicator(BuildContext context) {
    final authVM = context.watch<AuthViewmodel>();
    final profile = authVM.profile;
    if (profile == null) return const SizedBox.shrink();

    final bool isPremium = profile.plan.toLowerCase() == 'premium';

    return Row(
      children: [
        Expanded(
          child: _IndicatorBar(
            label: "Stylist",
            canUse: profile.canUseStylist,
            isPremium: isPremium,
            availableIn: profile.stylistAvailableIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _IndicatorBar(
            label: "Analysis",
            canUse: profile.canUseAnalysis,
            isPremium: isPremium,
            availableIn: profile.analysisAvailableIn,
          ),
        ),
      ],
    );
  }

  Widget _buildActionArea(StylistViewmodel stylistVM, String weatherContext) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Get Styled Button
            Expanded(
              child: ElevatedButton(
                onPressed: stylistVM.isLoading || stylistVM.isAnalyzing
                    ? null
                    : () async {
                        if ((context
                                    .read<AuthViewmodel>()
                                    .profile
                                    ?.wardrobeCount ??
                                0) ==
                            0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Your wardrobe is empty! Add some clothes first.",
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        await stylistVM.getRecommendation(
                          occasion: selectedOccasion,
                          weather: weatherContext,
                        );
                        if (stylistVM.status == StylistStatus.success) {
                          if (!mounted) return;
                          context.read<AuthViewmodel>().syncProfile();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Get Styled",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Analyze Closet Button
            Expanded(
              child: ElevatedButton(
                onPressed: stylistVM.isLoading || stylistVM.isAnalyzing
                    ? null
                    : () async {
                        if ((context
                                    .read<AuthViewmodel>()
                                    .profile
                                    ?.wardrobeCount ??
                                0) ==
                            0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Add some clothes to your wardrobe first!",
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        await stylistVM.runAnalysis(
                          stylePreference: selectedStylePreference,
                        );
                        if (stylistVM.status == StylistStatus.success) {
                          if (!mounted) return;
                          context.read<AuthViewmodel>().syncProfile();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF673AB7),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Color(0xFF673AB7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: stylistVM.isAnalyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Analyze Closet",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stylistVM.lookName!.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 14.4,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => stylistVM.resetRecommendation(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stylistVM.stylistTip ?? "",
                  style: GoogleFonts.manrope(
                    fontSize: 12.6,
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.color,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
        if (!stylistVM.isRecommendationSaved)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSaveOutfitDialog(context, stylistVM),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text("Save as Outfit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0AAE00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnalysisResult(
    StylistViewmodel stylistVM,
    Map<String, dynamic> data,
  ) {
    final List<dynamic> gaps = data['gaps'] ?? [];
    final List<dynamic> recommendations = data['recommendations'] ?? [];
    final int score = data['stylist_score'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        "Closet Audit",
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => stylistVM.resetAnalysis(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Score: $score",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['overview'] ?? "Your closet analysis is ready.",
            style: GoogleFonts.manrope(
              fontSize: 14.4,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildAnalysisSection(
            "Style Gaps",
            gaps,
            Icons.warning_amber_rounded,
            Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildAnalysisSection(
            "What to Buy Next",
            recommendations,
            Icons.shopping_bag_outlined,
            const Color(0xFF673AB7),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(
    String title,
    List<dynamic> items,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 15.3,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "  \u2022  ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(StylistViewmodel stylistVM) {
    final bool isLimitError = stylistVM.error?.contains("limit") ?? false;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            stylistVM.error ?? "Unknown error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          if (isLimitError)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlanScreen()),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: const Text("View Plans & Upgrade"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF673AB7),
                  backgroundColor: const Color(
                    0xFF673AB7,
                  ).withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSaveOutfitDialog(BuildContext context, StylistViewmodel stylistVM) {
    final TextEditingController nameController =
        TextEditingController(text: stylistVM.lookName);
    final outfitVM = context.read<OutfitViewmodel>();
    String? localError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              "Save AI Outfit",
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Give your new look a specific name to find it later in your closet.",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Outfit Name",
                    hintText: "e.g. Tropical Vacation",
                    errorText: localError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "Occasion: $selectedOccasion",
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: outfitVM.isSubmitting
                    ? null
                    : () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: outfitVM.isSubmitting
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => localError = "Name is required");
                          return;
                        }

                        final itemIds = stylistVM.recommendedItems!
                            .map((e) => e.id)
                            .toList();

                        final result = await outfitVM.createOutfit(
                          name: name,
                          occasion: selectedOccasion,
                          itemIds: itemIds,
                        );

                        if (result != null) {
                          stylistVM.markAsSaved();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text("Outfit saved to your closet!"),
                                ],
                              ),
                              backgroundColor: const Color(0xff0AAE00),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: "VIEW",
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          OutfitDetailScreen(outfit: result),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          // Extract cleaner error message if possible
                          String errorMsg =
                              outfitVM.error ?? "Failed to save outfit";
                          if (errorMsg.contains("already exists")) {
                            errorMsg = "An outfit with this name already exists";
                          }
                          setDialogState(() => localError = errorMsg);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: outfitVM.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Save Outfit"),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IndicatorBar extends StatelessWidget {
  final String label;
  final bool canUse;
  final bool isPremium;
  final String? availableIn;

  const _IndicatorBar({
    required this.label,
    required this.canUse,
    required this.isPremium,
    this.availableIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: canUse
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium
                ? Icons.auto_awesome
                : (canUse ? Icons.check_circle_outline : Icons.block_flipped),
            size: 14,
            color: canUse ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: GoogleFonts.manrope(
              fontSize: 11.7,
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              isPremium
                  ? "Unlimited"
                  : (canUse ? "Available" : (availableIn ?? 'Midnight')),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: canUse ? Colors.green.shade700 : Colors.red.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
