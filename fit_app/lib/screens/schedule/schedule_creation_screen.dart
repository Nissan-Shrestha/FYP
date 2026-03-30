import 'package:fit_app/constants.dart';
import 'package:fit_app/models/outfit_model.dart';
import 'package:fit_app/viewmodels/outfit_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ScheduleCreationScreen extends StatefulWidget {
  const ScheduleCreationScreen({super.key});

  @override
  State<ScheduleCreationScreen> createState() => _ScheduleCreationScreenState();
}

class _ScheduleCreationScreenState extends State<ScheduleCreationScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  OutfitModel? _selectedOutfit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OutfitViewmodel>().fetchOutfits();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10A8F5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitVM = context.watch<OutfitViewmodel>();
    final outfits = outfitVM.outfits;

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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "New Schedule",
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's the occasion?",
              style: GoogleFonts.caveat(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              hint: "e.g. Dinner with Friends, Office Meeting",
              icon: Icons.event_note,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildPickerTile(
                    label: "Date",
                    value: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    icon: Icons.calendar_today,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerTile(
                    label: "Time",
                    value: _selectedTime.format(context),
                    icon: Icons.access_time,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "Pick an Outfit",
              style: GoogleFonts.caveat(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (outfitVM.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (outfits.isEmpty)
              _buildEmptyOutfits()
            else
              _buildOutfitSelector(outfits),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedOutfit == null ? null : () {
                  // Logic to save schedule (coming soon)
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10A8F5),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Confirm Selection",
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.caveat(fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.caveat(color: Colors.grey, fontSize: 18),
          prefixIcon: Icon(icon, color: const Color(0xFF10A8F5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.caveat(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF10A8F5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitSelector(List<OutfitModel> outfits) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: outfits.length,
        itemBuilder: (context, index) {
          final outfit = outfits[index];
          final isSelected = _selectedOutfit?.id == outfit.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedOutfit = outfit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 150,
              margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4, left: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF10A8F5) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF10A8F5).withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Stack(
                        children: [
                          _buildOutfitPreview(outfit),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10A8F5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text(
                      capitalize(outfit.name),
                      style: GoogleFonts.caveat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildOutfitPreview(OutfitModel outfit) {
    if (outfit.items.isEmpty) {
      return Container(color: Colors.grey.shade200);
    }
    
    final imageUrl = outfit.items[0].image;
    final fullImageUrl = imageUrl != null
        ? (imageUrl.startsWith("http") ? imageUrl : "${ApiConfig.serverBaseUrl}$imageUrl")
        : null;

    return fullImageUrl != null
        ? Image.network(fullImageUrl, fit: BoxFit.cover, width: double.infinity)
        : Container(color: Colors.grey.shade200);
  }

  Widget _buildEmptyOutfits() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.style_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            "No outfits found",
            style: GoogleFonts.caveat(fontSize: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            "Create an outfit first to schedule it.",
            textAlign: TextAlign.center,
            style: GoogleFonts.caveat(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
