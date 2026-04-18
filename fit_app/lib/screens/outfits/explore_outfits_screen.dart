import 'dart:async';
import 'package:fit_app/constants.dart';
import 'package:fit_app/models/featured_wardrobe_model.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/screens/outfits/outfit_detail_screen.dart';
import 'package:fit_app/screens/wardrobe/wardrobe_view_screen.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fit_app/widgets/verified_badge.dart';

class ExploreOutfitsScreen extends StatefulWidget {
  const ExploreOutfitsScreen({super.key});

  @override
  State<ExploreOutfitsScreen> createState() => _ExploreOutfitsScreenState();
}

class _ExploreOutfitsScreenState extends State<ExploreOutfitsScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _discoveryController = PageController();
  Timer? _discoveryTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OutfitViewmodel>().fetchExploreFilters();
      context.read<OutfitViewmodel>().fetchExploreOutfits(refresh: true);
      context.read<OutfitViewmodel>().fetchFeaturedWardrobes().then((_) {
        _startAutoScroll();
      });
    });
  }

  void _startAutoScroll() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_discoveryController.hasClients) {
        final totalIndices = context
            .read<OutfitViewmodel>()
            .communityFeaturedWardrobes
            .length;
        if (totalIndices == 0) return;

        final currentPage = _discoveryController.page?.round() ?? 0;
        final nextPage = currentPage + 1;

        if (nextPage >= totalIndices) {
          _discoveryController.animateToPage(
            0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutCubic,
          );
        } else {
          _discoveryController.nextPage(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _discoveryController.dispose();
    _discoveryTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<OutfitViewmodel>().fetchExploreOutfits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(
          "Discovery",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 21.6,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context
                .read<OutfitViewmodel>()
                .fetchExploreOutfits(refresh: true),
            icon: const Icon(Icons.refresh, color: Colors.black54),
          ),
        ],
      ),
      body: Consumer<OutfitViewmodel>(
        builder: (context, vm, child) {
          if (vm.isLoadingExplore) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF673AB7)),
            );
          }

          final outfits = vm.exploreOutfits;
          final wardrobes = vm.communityFeaturedWardrobes;

          return Column(
            children: [
              _buildFilterBar(vm),
              Expanded(
                child: outfits.isEmpty && wardrobes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.explore_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Nothing here yet",
                              style: GoogleFonts.manrope(
                                fontSize: 21.6,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  vm.fetchExploreOutfits(refresh: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF673AB7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Refresh"),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await vm.fetchExploreOutfits(refresh: true);
                          await vm.fetchFeaturedWardrobes();
                        },
                        color: const Color(0xFF673AB7),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              outfits.length +
                              (wardrobes.isNotEmpty ? 1 : 0) +
                              (vm.hasMoreExplore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (wardrobes.isNotEmpty && index == 0) {
                              return _CommunityFeaturedWardrobesSection(
                                wardrobes: wardrobes,
                                controller: _discoveryController,
                              );
                            }
                            final outfitIndex = wardrobes.isNotEmpty
                                ? index - 1
                                : index;

                            if (outfitIndex == outfits.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF673AB7),
                                  ),
                                ),
                              );
                            }

                            final outfit = outfits[outfitIndex];
                            if (outfitIndex == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 24,
                                      bottom: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.people_rounded,
                                          color: Colors.blueAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Shared Outfits",
                                          style: GoogleFonts.manrope(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _ExploreOutfitCard(outfit: outfit),
                                ],
                              );
                            }

                            return _ExploreOutfitCard(outfit: outfit);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(OutfitViewmodel vm) {
    // Show static list if none from API yet
    final occasions = vm.availableOccasions.isNotEmpty
        ? ["All", ...vm.availableOccasions]
        : ["All", "Casual", "Work", "Party", "Formal"];

    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: occasions.length,
        itemBuilder: (context, index) {
          final occ = occasions[index];
          final isAll = occ == "All";
          final isActive = isAll
              ? vm.selectedOccasion == null
              : vm.selectedOccasion == occ;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(occ),
              selected: isActive,
              onSelected: (val) {
                if (val) {
                  vm.setFilters(occasion: isAll ? null : occ);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF673AB7),
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 11.7,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isActive ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}

class _ExploreOutfitCard extends StatelessWidget {
  final OutfitModel outfit;

  const _ExploreOutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewmodel>();
    final currentUid = authVM.profile?.firebaseUid;
    final isOwnOutfit = outfit.ownerFirebaseUid == currentUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: outfit.ownerProfilePicture != null
                      ? NetworkImage(
                          outfit.ownerProfilePicture!.startsWith("http")
                              ? outfit.ownerProfilePicture!
                              : "${ApiConfig.serverBaseUrl}${outfit.ownerProfilePicture!}",
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            outfit.ownerUsername ?? "User",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          if (outfit.ownerIsFeatured) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(size: 14),
                          ],
                        ],
                      ),
                      Text(
                        capitalize(outfit.name),
                        style: GoogleFonts.manrope(
                          fontSize: 14.4,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (outfit.ownerBio?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            outfit.ownerBio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 10.8,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffEDF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    outfit.occasion,
                    style: const TextStyle(
                      fontSize: 10.8,
                      color: Color(0xff0AAE00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image Area
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OutfitDetailScreen(outfit: outfit, readOnly: true),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: outfit.items.length,
                itemBuilder: (context, index) {
                  final item = outfit.items[index];
                  final url = item.image == null
                      ? null
                      : (item.image!.startsWith("http")
                            ? item.image!
                            : "${ApiConfig.serverBaseUrl}${item.image!}");
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.grey.shade50,
                      child: url != null
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.checkroom, size: 20),
                            )
                          : const Icon(
                              Icons.checkroom,
                              color: Colors.grey,
                              size: 20,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Footer
          if (!isOwnOutfit)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context
                        .read<OutfitViewmodel>()
                        .toggleSaveOutfit(outfit),
                    icon: Icon(
                      outfit.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: outfit.isSaved
                          ? const Color(0xFF673AB7)
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    "${outfit.savesCount}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: outfit.isSaved
                          ? const Color(0xFF673AB7)
                          : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      final result = await _showReportDialog(
                        context,
                        "Report Outfit",
                      );
                      if (result != null && context.mounted) {
                        await context.read<OutfitViewmodel>().reportOutfit(
                          outfit.id,
                          result["reason"]!,
                          description: result["description"],
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Reported")),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.report_problem_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16), // Bottom padding for own outfits
        ],
      ),
    );
  }
}

class _CommunityFeaturedWardrobesSection extends StatelessWidget {
  final List<CommunityFeaturedWardrobeModel> wardrobes;
  final PageController controller;

  const _CommunityFeaturedWardrobesSection({
    required this.wardrobes,
    required this.controller,
  });

  Future<void> _launchUrl(String handle, String platform) async {
    final cleanHandle = handle.startsWith('@') ? handle.substring(1) : handle;
    String url;
    switch (platform.toLowerCase()) {
      case 'instagram':
        url = 'https://instagram.com/$cleanHandle';
        break;
      case 'twitter':
        url = 'https://twitter.com/$cleanHandle';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$cleanHandle';
        break;
      default:
        return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSocialLinks(Map<String, dynamic>? socials) {
    if (socials == null) return const SizedBox.shrink();

    List<Widget> icons = [];

    if (socials['instagram']?.isNotEmpty == true) {
      icons.add(
        _SocialIcon(
          icon: FontAwesomeIcons.instagram,
          color: Colors.pinkAccent,
          onTap: () => _launchUrl(socials['instagram'], 'instagram'),
        ),
      );
    }

    if (socials['twitter']?.isNotEmpty == true) {
      icons.add(
        _SocialIcon(
          icon: FontAwesomeIcons.twitter,
          color: Colors.lightBlueAccent,
          onTap: () => _launchUrl(socials['twitter'], 'twitter'),
        ),
      );
    }

    if (socials['tiktok']?.isNotEmpty == true) {
      icons.add(
        _SocialIcon(
          icon: FontAwesomeIcons.tiktok,
          color: Colors.black,
          onTap: () => _launchUrl(socials['tiktok'], 'tiktok'),
        ),
      );
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons
          .map(
            (w) => Padding(padding: const EdgeInsets.only(left: 8), child: w),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 28,
                color: Color(0xffFFB800),
              ),
              const SizedBox(width: 8),
              Text(
                "Featured Discovery",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: controller,
            itemCount: wardrobes.length,
            itemBuilder: (context, index) {
              final lb = wardrobes[index];
              final socials = lb.owner.socialLinks;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tappable Image Grid
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WardrobeViewScreen(
                                  wardrobeId: lb.wardrobe.id,
                                  wardrobeName: lb.wardrobe.name,
                                  readOnly: true,
                                ),
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 4.0;
                                const padding = 4.0;
                                final cellWidth =
                                    (constraints.maxWidth -
                                        (padding * 2) -
                                        (spacing * 2)) /
                                    3;
                                final cellHeight =
                                    (constraints.maxHeight -
                                        (padding * 2) -
                                        spacing) /
                                    2;
                                final aspectRatio = cellWidth / cellHeight;

                                return Container(
                                  color: Colors.grey.shade50,
                                  padding: const EdgeInsets.all(padding),
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: spacing,
                                          mainAxisSpacing: spacing,
                                          childAspectRatio: aspectRatio,
                                        ),
                                    itemCount: 6,
                                    itemBuilder: (context, i) {
                                      final item =
                                          (lb.previewItems != null &&
                                              lb.previewItems!.length > i)
                                          ? lb.previewItems![i]
                                          : null;
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: item?.image != null
                                              ? Image.network(
                                                  item!.image!.startsWith(
                                                        "http",
                                                      )
                                                      ? item.image!
                                                      : "${ApiConfig.serverBaseUrl}${item.image!}",
                                                  fit: BoxFit.contain,
                                                )
                                              : const Icon(
                                                  Icons.checkroom,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Interaction Area
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Owner Row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage:
                                        lb.owner.profilePicture != null
                                        ? NetworkImage(
                                            lb.owner.profilePicture!.startsWith(
                                                  "http",
                                                )
                                                ? lb.owner.profilePicture!
                                                : "${ApiConfig.serverBaseUrl}${lb.owner.profilePicture!}",
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            lb.owner.username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.7,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (lb.owner.isFeatured) ...[
                                          const SizedBox(width: 4),
                                          const VerifiedBadge(size: 12),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xffFFB800,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "FEATURED",
                                      style: TextStyle(
                                        fontSize: 7.2,
                                        color: Color(0xffD49D00),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              // Wardrobe & Social Row
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WardrobeViewScreen(
                                            wardrobeId: lb.wardrobe.id,
                                            wardrobeName: lb.wardrobe.name,
                                            readOnly: true,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        lb.wardrobe.name,
                                        style: GoogleFonts.manrope(
                                          fontSize: 16.2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  _buildSocialLinks(socials),
                                  if (lb.owner.firebaseUid !=
                                      context
                                          .read<AuthViewmodel>()
                                          .profile
                                          ?.firebaseUid)
                                    IconButton(
                                      onPressed: () async {
                                        final result = await _showReportDialog(
                                          context,
                                          "Report Wardrobe",
                                        );
                                        if (result != null && context.mounted) {
                                          await context
                                              .read<OutfitViewmodel>()
                                              .reportFeaturedWardrobe(
                                                lb.requestId,
                                                result["reason"]!,
                                                description:
                                                    result["description"],
                                              );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Wardrobe Reported",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.only(left: 8),
                                      icon: const Icon(
                                        Icons.report_problem_outlined,
                                        size: 18,
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final dynamic icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: FaIcon(icon, color: color, size: 14),
      ),
    );
  }
}

Future<Map<String, String>?> _showReportDialog(
  BuildContext context,
  String title,
) async {
  String? selectedReason;
  final descController = TextEditingController();

  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedReason,
              hint: const Text("Select a reason"),
              items: [
                "Inappropriate",
                "Spam",
                "Copyright",
                "Other",
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setDialogState(() => selectedReason = v),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Additional details (optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: selectedReason == null
                ? null
                : () => Navigator.pop(context, {
                    "reason": selectedReason!,
                    "description": descController.text,
                  }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    ),
  );
}
