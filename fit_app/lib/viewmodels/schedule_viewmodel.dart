import 'package:fit_app/models/schedule_model.dart';
import 'package:fit_app/services/schedule_service.dart';
import 'package:flutter/material.dart';

class ScheduleViewmodel extends ChangeNotifier {
  List<ScheduleModel> schedules = [];
  bool isLoading = false;
  String? error;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchSchedules(date: date);
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchSchedules({DateTime? date}) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final dateStr = _formatDate(date ?? _selectedDate);
      schedules = await ScheduleService.fetchSchedules(date: dateStr);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ScheduleModel?> createSchedule({
    required String eventTitle,
    required DateTime dateTime,
    required int outfitId,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final schedule = await ScheduleService.createSchedule(
        eventTitle: eventTitle,
        dateTime: dateTime,
        outfitId: outfitId,
      );

      // Refresh list if the date matches
      if (_formatDate(dateTime) == _formatDate(_selectedDate)) {
        schedules = [schedule, ...schedules];
      }
      return schedule;
    } catch (e) {
      error = "Failed to create schedule: ${e.toString()}";
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper for creating from view
  Future<bool> scheduleOutfit({
    required String eventTitle,
    required DateTime date,
    required TimeOfDay time,
    required int outfitId,
  }) async {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final result = await createSchedule(
      eventTitle: eventTitle,
      dateTime: dateTime,
      outfitId: outfitId,
    );

    return result != null;
  }

  Future<bool> deleteSchedule(int scheduleId) async {
    try {
      await ScheduleService.deleteSchedule(scheduleId);
      schedules = schedules.where((s) => s.id != scheduleId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
