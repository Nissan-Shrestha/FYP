import 'package:fit_app/models/outfit_model.dart';

class ScheduleModel {
  final int id;
  final String eventTitle;
  final DateTime dateTime;
  final int outfitId;
  final OutfitModel? outfitDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.eventTitle,
    required this.dateTime,
    required this.outfitId,
    this.outfitDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      eventTitle: json['event_title'],
      dateTime: DateTime.parse(json['date_time']),
      outfitId: json['outfit'],
      outfitDetails: json['outfit_details'] != null
          ? OutfitModel.fromJson(json['outfit_details'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_title': eventTitle,
      'date_time': dateTime.toIsoformat(),
      'outfit': outfitId,
      'created_at': createdAt.toIsoformat(),
      'updated_at': updatedAt.toIsoformat(),
    };
  }
}

extension DateTimeX on DateTime {
  String toIsoformat() {
    return toIso8601String();
  }
}
