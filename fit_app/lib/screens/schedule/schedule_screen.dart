import 'package:fit_app/constants.dart';
import 'package:fit_app/models/schedule_model.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/screens/outfits/outfit_detail_screen.dart';
import 'package:fit_app/viewmodels/schedule_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fit_app/screens/schedule/schedule_creation_screen.dart';
import 'package:provider/provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleViewmodel>().fetchSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVM = context.watch<ScheduleViewmodel>();
    final schedules = scheduleVM.schedules;

    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xffF6F6F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Fit Calendar",
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => scheduleVM.fetchSchedules(),
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildDateStrip(scheduleVM),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Scheduled Outfits",
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (schedules.isNotEmpty)
                  Text(
                    "${schedules.length} Event${schedules.length == 1 ? '' : 's'}",
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      color: const Color(0xFF10A8F5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: scheduleVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : scheduleVM.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            "Error: ${scheduleVM.error}",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.caveat(fontSize: 18, color: Colors.red),
                          ),
                        ),
                      )
                    : schedules.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(context, schedules[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScheduleCreationScreen()),
          );
          if (!context.mounted) return;
          context.read<ScheduleViewmodel>().fetchSchedules();
        },
        backgroundColor: const Color(0xFF10A8F5),
        elevation: 4,
        label: Text(
          "Schedule Outfit",
          style: GoogleFonts.caveat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDateStrip(ScheduleViewmodel vm) {
    final now = DateTime.now();
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // 2 weeks
        itemBuilder: (context, index) {
          final date = now.add(Duration(days: index));
          final isSelected = date.day == vm.selectedDate.day &&
              date.month == vm.selectedDate.month &&
              date.year == vm.selectedDate.year;

          return GestureDetector(
            onTap: () => vm.setSelectedDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF10A8F5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10A8F5).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(date.weekday - 1) % 7],
                    style: GoogleFonts.caveat(
                      fontSize: 15,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.caveat(
                      fontSize: 24,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No plans for today",
            style: GoogleFonts.caveat(fontSize: 22, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the button below to schedule an outfit.",
            style: GoogleFonts.caveat(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, ScheduleModel schedule) {
    final outfit = schedule.outfitDetails;
    final timeStr = "${schedule.dateTime.hour.toString().padLeft(2, '0')}:${schedule.dateTime.minute.toString().padLeft(2, '0')}";

    return Dismissible(
      key: Key(schedule.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<ScheduleViewmodel>().deleteSchedule(schedule.id);
      },
      child: InkWell(
        onTap: () {
          if (outfit != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OutfitDetailScreen(outfit: outfit, readOnly: true),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 8,
                    color: const Color(0xFF10A8F5),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10A8F5).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: Color(0xFF10A8F5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  schedule.eventTitle,
                                  style: GoogleFonts.caveat(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  outfit?.name ?? "No outfit selected",
                                  style: GoogleFonts.caveat(
                                    fontSize: 17,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          if (outfit != null)
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: _buildGridPreview(outfit),
                            )
                          else
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.style, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridPreview(OutfitModel outfit) {
    final previewItems = outfit.items.take(4).toList();
    final imageUrls = previewItems
        .map((item) => item.image)
        .whereType<String>()
        .map((path) => path.startsWith("http") ? path : "${ApiConfig.serverBaseUrl}$path")
        .toList();

    final imageSlots = List<String?>.generate(
      4,
      (index) => index < imageUrls.length ? imageUrls[index] : null,
    );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[0])),
                const SizedBox(width: 8),
                Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[1])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[2])),
                const SizedBox(width: 8),
                Expanded(child: _MiniPreviewBox(imageUrl: imageSlots[3])),
              ],
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey.shade300,
          child: imageUrl == null
              ? const SizedBox.shrink()
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(Icons.error_outline, size: 16),
                ),
        ),
      ),
    );
  }
}
