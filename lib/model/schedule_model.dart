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
