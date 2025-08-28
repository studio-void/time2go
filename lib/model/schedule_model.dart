import 'package:flutter/material.dart';

class ScheduleModel {
  final int day;
  final TimeOfDay start;
  final TimeOfDay end;
  final String title;
  final Color color;

  ScheduleModel({
    required this.day,
    required this.start,
    required this.end,
    required this.title,
    required this.color,
  });

  factory ScheduleModel.fromFirestore(Map<String, dynamic> data) {
    return ScheduleModel(
      day: data['day'] ?? 0,
      start: TimeOfDay(
        hour: data['startHour'] ?? 0,
        minute: data['startMinute'] ?? 0,
      ),
      end: TimeOfDay(
        hour: data['endHour'] ?? 0,
        minute: data['endMinute'] ?? 0,
      ),
      title: data['title'] ?? '',
      color: Color(data['color'] ?? 0xFF90CAF9),
    );
  }

  ScheduleModel copyWith({
    int? day,
    TimeOfDay? start,
    TimeOfDay? end,
    String? title,
    Color? color,
  }) {
    return ScheduleModel(
      day: day ?? this.day,
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
      color: color ?? this.color,
    );
  }
}
