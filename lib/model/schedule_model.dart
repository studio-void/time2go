import 'package:flutter/material.dart';

class ScheduleModel {
  final int day;
  final TimeOfDay start;
  final TimeOfDay end;
  final String title;

  ScheduleModel({
    required this.day,
    required this.start,
    required this.end,
    required this.title,
  });

  ScheduleModel copyWith({
    int? day,
    TimeOfDay? start,
    TimeOfDay? end,
    String? title,
  }) {
    return ScheduleModel(
      day: day ?? this.day,
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
    );
  }
}
