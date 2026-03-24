import 'package:fit_app/constants.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/screens/notifications/notification_screen.dart';
import 'package:fit_app/screens/outfits/create_outfit_screen.dart';
import 'package:fit_app/screens/schedule/schedule_screen.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OutfitViewmodel>().fetchOutfits();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitVM = context.watch<OutfitViewmodel>();
    final outfits = outfitVM.outfits;

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          "Outfits",
          style: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              );
            },
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => outfitVM.fetchOutfits(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Outfit Suggestion for Today",
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildOutfitSuggestion(),
                const SizedBox(height: 20),
                Text(
                  "Create an Outfit",
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateOutfitScreen()),
                    );
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          "Create new outfits",
                          style: GoogleFonts.caveat(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "My Outfits",
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (outfitVM.isLoading && outfits.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (outfits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No outfits created yet",
                        style: GoogleFonts.caveat(fontSize: 18),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 20,
                    ),
                    itemCount: outfits.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _OutfitCard(outfit: outfits[index]);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitSuggestion() {
    return Container(
      height: 200,
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade400,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                      "https://www.realsimple.com/thmb/46MVTJ_t0HSHaVFUNeu0dhBWvhY=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/what-to-wear-Formal-events-fd6eff677fe84b05b11e99eb8c2cc14f.jpg",
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber),
                  const SizedBox(height: 8),
                  Text(
                    "AI Suggestions coming soon",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final OutfitModel outfit;

  const _OutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    // Get up to 4 preview images
    final previewItems = outfit.items.take(4).toList();

    return InkWell(
      onTap: () {
        // TODO: View outfit details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildGridPreview(previewItems),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            outfit.name,
            style: GoogleFonts.caveat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "${outfit.items.length} item${outfit.items.length == 1 ? "" : "s"}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGridPreview(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(child: Icon(Icons.checkroom, color: Colors.grey));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = (constraints.maxWidth - 4) / 2;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: items.map((item) {
            final imageUrl = item.image == null
                ? null
                : item.image!.startsWith("http")
                    ? item.image!
                    : "${ApiConfig.serverBaseUrl}${item.image!}";

            return Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.checkroom, size: 16),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

