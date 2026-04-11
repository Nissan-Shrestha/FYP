import 'package:fit_app/constants.dart';
import 'package:fit_app/models/featured_wardrobe_model.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FeaturedRequestsScreen extends StatefulWidget {
  const FeaturedRequestsScreen({super.key});

  @override
  State<FeaturedRequestsScreen> createState() => _FeaturedRequestsScreenState();
}

class _FeaturedRequestsScreenState extends State<FeaturedRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeViewmodel>().fetchFeaturedWardrobeRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: Text(
          "Feature Status",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<WardrobeViewmodel>(
        builder: (context, vm, child) {
          if (vm.isLoadingRequests && vm.featuredWardrobeRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF673AB7)));
          }

          final requests = vm.featuredWardrobeRequests;

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No feature requests yet",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You can feature your wardrobes from the Wardrobe View.",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => vm.fetchFeaturedWardrobeRequests(),
            color: const Color(0xFF673AB7),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return _FeatureRequestCard(request: requests[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FeatureRequestCard extends StatelessWidget {
  final FeaturedWardrobeModel request;

  const _FeatureRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText = request.status.toUpperCase();

    switch (request.status) {
      case 'approved':
        statusColor = const Color(0xff0AAE00);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xffFFB800);
        statusIcon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capitalize(request.wardrobeName ?? 'ID #${request.wardrobe}'),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (request.status == 'approved')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff0AAE00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "LIVE",
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0AAE00),
                    ),
                  ),
                ),
            ],
          ),
          if (request.adminFeedback != null && request.adminFeedback!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          "Admin Feedback",
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.adminFeedback!,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Requested on ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              if (request.status == 'pending')
                 const Text(
                  "Reviewing",
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
