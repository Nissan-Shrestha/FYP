import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleCreationScreen extends StatefulWidget {
  const ScheduleCreationScreen({super.key});

  @override
  State<ScheduleCreationScreen> createState() => _ScheduleCreationScreenState();
}

class _ScheduleCreationScreenState extends State<ScheduleCreationScreen> {
  String selectedDay = "Select Day";
  String selectedMonth = "Select Month";
  String selectedYear = "Select Year";
  String selectedTime = "Select Time";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Fit Calender",
          style: GoogleFonts.caveat(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          children: [
            const _EventNameField(),
            const SizedBox(height: 20),
            _SelectRow(
              label: selectedDay,
              onTap: () => _openPickerSheet(
                title: "Select Day",
                subtitle: "Choose a day for the outfit schedule",
                options: List.generate(31, (i) => "${i + 1}"),
                onSelected: (value) => setState(() => selectedDay = value),
              ),
            ),
            const SizedBox(height: 12),
            _SelectRow(
              label: selectedMonth,
              onTap: () => _openPickerSheet(
                title: "Select Month",
                subtitle: "Placeholder month options",
                options: const [
                  "January",
                  "February",
                  "March",
                  "April",
                  "May",
                  "June",
                  "July",
                  "August",
                  "September",
                  "October",
                  "November",
                  "December",
                ],
                onSelected: (value) => setState(() => selectedMonth = value),
              ),
            ),
            const SizedBox(height: 12),
            _SelectRow(
              label: selectedYear,
              onTap: () => _openPickerSheet(
                title: "Select Year",
                subtitle: "Placeholder year options",
                options: const ["2025", "2026", "2027", "2028"],
                onSelected: (value) => setState(() => selectedYear = value),
              ),
            ),
            const SizedBox(height: 12),
            _SelectRow(
              label: selectedTime,
              onTap: _openTimeSheet,
            ),
            const SizedBox(height: 18),
            Text(
              "Select the outfit for the day",
              style: GoogleFonts.caveat(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black45),
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.black, size: 24),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12A3EE),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Save",
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPickerSheet({
    required String title,
    required String subtitle,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(option),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          onSelected(option);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTimeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final timeOptions = [
          "08:00 AM",
          "10:30 AM",
          "12:00 PM",
          "03:15 PM",
          "06:00 PM",
          "08:45 PM",
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Time",
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Placeholder time slots for scheduling",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timeOptions
                      .map(
                        (time) => ActionChip(
                          label: Text(time),
                          onPressed: () {
                            setState(() => selectedTime = time);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => selectedTime = "Custom Time");
                      Navigator.pop(context);
                    },
                    child: const Text("Use custom time (placeholder)"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventNameField extends StatelessWidget {
  const _EventNameField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        style: GoogleFonts.caveat(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: "Name of the event",
          hintStyle: GoogleFonts.caveat(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SelectRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xffD9D9D9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.caveat(
                  fontSize: 17,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700, size: 18),
          ],
        ),
      ),
    );
  }
}
