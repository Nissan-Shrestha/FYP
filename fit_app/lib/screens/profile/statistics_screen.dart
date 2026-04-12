import 'package:fit_app/constants.dart';
import 'package:fit_app/screens/profile/financial_report_screen.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final wardrobeVM = context.watch<WardrobeViewmodel>();
    final outfitVM = context.watch<OutfitViewmodel>();
    final items = wardrobeVM.clothingItems;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(
          "Wardrobe Insights",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 21.6,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(wardrobeVM, outfitVM),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    "Top 5 Categories",
                    subtitle: "A breakdown of your most populated categories.",
                  ),
                  _buildCategoryChart(wardrobeVM.getCategoryDistribution()),
                  const SizedBox(height: 40),
                  _buildSectionTitle(
                    "Seasonal Distribution",
                    subtitle: "How your closet is balanced across the year.",
                  ),
                  _buildSeasonChart(wardrobeVM.getSeasonDistribution()),
                  const SizedBox(height: 40),
                  _buildSectionTitle(
                    "Top Colors",
                    subtitle: "The most dominant colors in your collection.",
                  ),
                  _buildColorPalette(wardrobeVM.getColorDistribution()),
                  const SizedBox(height: 40),
                  _buildSectionTitle(
                    "Cost Per Wear & Value",
                    subtitle:
                        "Items that are giving you the best return on investment.",
                  ),
                  _buildCostPerWearSection(wardrobeVM),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Add items to see insights",
            style: GoogleFonts.manrope(fontSize: 16.2, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 17.1,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 10.8,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(WardrobeViewmodel wVM, OutfitViewmodel oVM) {
    return Row(
      children: [
        _statCard("Items", wVM.clothingItems.length.toString(), Colors.blue),
        const SizedBox(width: 12),
        _statCard("Wardrobes", wVM.wardrobes.length.toString(), Colors.purple),
        const SizedBox(width: 12),
        _statCard("Outfits", oVM.outfits.length.toString(), Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 21.6,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10.8,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, int> counts) {
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartColors = [
      const Color(0xFF673AB7),
      const Color(0xFF9575CD),
      const Color(0xFFB39DDB),
      const Color(0xFFD1C4E9),
      const Color(0xFFEDE7F6),
    ];

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 45,
                sections: List.generate(
                  sortedEntries.length > 5 ? 5 : sortedEntries.length,
                  (i) {
                    final isTouched = i == touchedIndex;
                    final fontSize = isTouched ? 18.0 : 12.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    return PieChartSectionData(
                      color: chartColors[i % chartColors.length],
                      value: sortedEntries[i].value.toDouble(),
                      title:
                          '${((sortedEntries[i].value / counts.values.fold(0, (sum, v) => sum + v)) * 100).toStringAsFixed(0)}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                sortedEntries.length > 5 ? 5 : sortedEntries.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: chartColors[i % chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sortedEntries[i].key,
                          style: GoogleFonts.manrope(
                            fontSize: 10.8,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonChart(Map<String, int> counts) {
    if (counts.isEmpty) return const SizedBox.shrink();

    final seasonNames = counts.keys.toList()..sort();
    final maxCount = counts.values.isNotEmpty
        ? counts.values.reduce((a, b) => a > b ? a : b)
        : 0;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount > 0 ? maxCount * 1.4 : 10,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final totalItems = counts.values.fold(0, (sum, v) => sum + v);
                final pct = totalItems == 0
                    ? "0"
                    : ((rod.toY / totalItems) * 100).toStringAsFixed(0);
                return BarTooltipItem(
                  '$pct%',
                  GoogleFonts.manrope(
                    color: const Color(0xFF673AB7),
                    fontWeight: FontWeight.w900,
                    fontSize: 10.8,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= seasonNames.length) {
                    return const SizedBox();
                  }
                  String name = seasonNames[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 3
                          ? name.substring(0, 3).toUpperCase()
                          : name.toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.0,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(seasonNames.length, (i) {
            final val = counts[seasonNames[i]]!.toDouble();
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF673AB7), Color(0xFF9575CD)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildColorPalette(Map<String, int> colorCounts) {
    if (colorCounts.isEmpty) return const SizedBox();

    final sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: sortedColors.take(8).map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.key,
                style: GoogleFonts.manrope(
                  fontSize: 11.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.value.toString(),
                style: GoogleFonts.manrope(
                  fontSize: 11.7,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF673AB7).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCostPerWearSection(WardrobeViewmodel wardrobeVM) {
    final pricedItems = wardrobeVM.getPricedItemsSortedByCPW();

    if (pricedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Add prices to your items to see Cost Per Wear insights.",
                style: GoogleFonts.manrope(
                  fontSize: 12.6,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalValue = wardrobeVM.totalWardrobeValue;

    // Best Value = Lowest CPW
    final bestValueItems = wardrobeVM.getPricedItemsSortedByCPW(descending: false);

    // To Revisit = Highest CPW
    final needsLoveItems = pricedItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Total Value Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Wardrobe Value",
                    style: GoogleFonts.manrope(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${totalValue.toStringAsFixed(2)}",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 25.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 2. Best Value (The Workhorses)
        _buildSubsectionTitle("Wardrobe Workhorses", "Lowest cost per wear"),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bestValueItems.length > 5 ? 5 : bestValueItems.length,
            itemBuilder: (context, index) {
              final item = bestValueItems[index];
              return _buildValueCard(item, isBestValue: true);
            },
          ),
        ),

        const SizedBox(height: 32),

        // 3. Needs More Love (Highest CPW)
        _buildSubsectionTitle("Items to Revisit", "Highest cost per wear"),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: needsLoveItems.length > 5 ? 5 : needsLoveItems.length,
          itemBuilder: (context, index) {
            final item = needsLoveItems[index];
            final cpw =
                item.purchasePrice! / (item.wearCount > 0 ? item.wearCount : 1);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  _buildItemThumbnail(item),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(item, cpw),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${cpw.toStringAsFixed(2)}",
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.4,
                          color: const Color(0xff0AAE00),
                        ),
                      ),
                      Text(
                        item.wearCount > 0
                            ? "Worn ${item.wearCount}x"
                            : "Not worn yet",
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        if (pricedItems.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinancialReportScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Text(
                  "View Full Financial Report",
                  style: GoogleFonts.manrope(
                    fontSize: 12.6,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF673AB7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubsectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 14.4,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemThumbnail(dynamic item) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: item.image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.image!.startsWith("http")
                    ? item.image!
                    : "${ApiConfig.serverBaseUrl}${item.image!}",
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.checkroom, color: Colors.grey),
    );
  }

  Widget _buildValueCard(dynamic item, {required bool isBestValue}) {
    final cpw = item.purchasePrice! / (item.wearCount > 0 ? item.wearCount : 1);
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.image!.startsWith("http")
                          ? item.image!
                          : "${ApiConfig.serverBaseUrl}${item.image!}",
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.checkroom, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 10.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "\$${cpw.toStringAsFixed(2)}",
                  style: GoogleFonts.manrope(
                    fontSize: 11.7,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xff0AAE00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic item, double cpw) {
    String label = "Good Value";
    Color bgColor = Colors.blue.shade50;
    Color textColor = Colors.blue.shade700;

    if (item.wearCount == 0) {
      label = "New Investment";
      bgColor = const Color(0xffE3F2FD);
      textColor = const Color(0xff1976D2);
    } else if (cpw <= 10) {
      label = "Excellent Value";
      bgColor = const Color(0xffE8F5E9);
      textColor = const Color(0xff2E7D32);
    } else if (cpw >= 50) {
      label = "Needs Attention";
      bgColor = const Color(0xffFFF3E0);
      textColor = const Color(0xffE65100);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}
