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
                      MaterialPageRoute(
                        builder: (_) => const CreateOutfitScreen(),
                      ),
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 18,
                      childAspectRatio:
                          (MediaQuery.of(context).size.width / 2) / 280,
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
    final imageUrls = previewItems
        .map((item) => item.image)
        .whereType<String>()
        .map(
          (path) => path.startsWith("http")
              ? path
              : "${ApiConfig.serverBaseUrl}$path",
        )
        .toList();

    // Fill slots for 2x2 grid
    final imageSlots = List<String?>.generate(
      4,
      (index) => index < imageUrls.length ? imageUrls[index] : null,
    );

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[0])),
                      const SizedBox(width: 10),
                      Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[1])),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[2])),
                      const SizedBox(width: 10),
                      Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[3])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          capitalize(outfit.name),
          style: GoogleFonts.caveat(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "${outfit.items.length} item${outfit.items.length == 1 ? "" : "s"}",
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

class _MiniPreviewBox extends StatelessWidget {
  final String? imageUrl;
  const _MiniPreviewBox({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.grey.shade300,
          child: imageUrl == null
              ? const SizedBox.shrink()
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}
