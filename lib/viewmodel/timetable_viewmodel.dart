import 'package:flutter/material.dart';
import '../model/schedule_model.dart';

class TimetableViewModel extends ChangeNotifier {
  List<ScheduleModel> _schedules = [
    ScheduleModel(
      day: 0,
      start: TimeOfDay(hour: 9, minute: 0),
      end: TimeOfDay(hour: 11, minute: 0),
      title: '수학',
    ),
    ScheduleModel(
      day: 2,
      start: TimeOfDay(hour: 13, minute: 0),
      end: TimeOfDay(hour: 15, minute: 0),
      title: '과학 실험',
    ),
    ScheduleModel(
      day: 4,
      start: TimeOfDay(hour: 18, minute: 0),
      end: TimeOfDay(hour: 20, minute: 0),
      title: '동아리',
    ),
    ScheduleModel(
      day: 1,
      start: TimeOfDay(hour: 8, minute: 0),
      end: TimeOfDay(hour: 10, minute: 0),
      title: '영어',
    ),
    ScheduleModel(
      day: 3,
      start: TimeOfDay(hour: 15, minute: 0),
      end: TimeOfDay(hour: 17, minute: 0),
      title: '음악',
    ),
    ScheduleModel(
      day: 0,
      start: TimeOfDay(hour: 12, minute: 0),
      end: TimeOfDay(hour: 13, minute: 0),
      title: '체육',
    ),
    ScheduleModel(
      day: 2,
      start: TimeOfDay(hour: 17, minute: 0),
      end: TimeOfDay(hour: 18, minute: 0),
      title: '미술',
    ),
    ScheduleModel(
      day: 1,
      start: TimeOfDay(hour: 20, minute: 0),
      end: TimeOfDay(hour: 22, minute: 0),
      title: '독서',
    ),
    ScheduleModel(
      day: 3,
      start: TimeOfDay(hour: 10, minute: 0),
      end: TimeOfDay(hour: 12, minute: 0),
      title: '프로그래밍',
    ),
  ];

  List<ScheduleModel> get schedules => List.unmodifiable(_schedules);

  void addOrSplitBlock(int day, int startHour, int endHour, String title) {
    final newStart = startHour;
    final newEnd = endHour;
    List<ScheduleModel> newList = [];
    for (final s in _schedules) {
      if (s.day != day) {
        newList.add(s);
        continue;
      }
      final sStart = s.start.hour;
      final sEnd = s.end.hour;
      if (sEnd <= newStart || sStart >= newEnd) {
        newList.add(s);
        continue;
      }
      if (sStart < newStart) {
        newList.add(
          ScheduleModel(
            day: day,
            start: TimeOfDay(hour: sStart, minute: 0),
            end: TimeOfDay(hour: newStart, minute: 0),
            title: s.title,
          ),
        );
      }
      if (sEnd > newEnd) {
        newList.add(
          ScheduleModel(
            day: day,
            start: TimeOfDay(hour: newEnd, minute: 0),
            end: TimeOfDay(hour: sEnd, minute: 0),
            title: s.title,
          ),
        );
      }
    }
    newList.add(
      ScheduleModel(
        day: day,
        start: TimeOfDay(hour: newStart, minute: 0),
        end: TimeOfDay(hour: newEnd, minute: 0),
        title: title,
      ),
    );
    _schedules = newList;
    notifyListeners();
  }
}
