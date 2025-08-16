import 'package:flutter/material.dart';
import 'schedule_block.dart';
import 'package:time2go/theme/time2go_theme.dart';

class TimetableWidget extends StatefulWidget {
  const TimetableWidget({super.key});

  @override
  State<TimetableWidget> createState() => _TimetableWidgetState();
}

class _TimetableWidgetState extends State<TimetableWidget> {
  List<Map<String, dynamic>> schedules = [
    {
      'day': 0,
      'start': const TimeOfDay(hour: 9, minute: 0),
      'end': const TimeOfDay(hour: 11, minute: 0),
      'title': '수학',
    },
    {
      'day': 2,
      'start': const TimeOfDay(hour: 13, minute: 0),
      'end': const TimeOfDay(hour: 15, minute: 0),
      'title': '과학 실험',
    },
    {
      'day': 4,
      'start': const TimeOfDay(hour: 18, minute: 0),
      'end': const TimeOfDay(hour: 20, minute: 0),
      'title': '동아리',
    },
    {
      'day': 1,
      'start': const TimeOfDay(hour: 8, minute: 0),
      'end': const TimeOfDay(hour: 10, minute: 0),
      'title': '영어',
    },
    {
      'day': 3,
      'start': const TimeOfDay(hour: 15, minute: 0),
      'end': const TimeOfDay(hour: 17, minute: 0),
      'title': '음악',
    },
    {
      'day': 0,
      'start': const TimeOfDay(hour: 12, minute: 0),
      'end': const TimeOfDay(hour: 13, minute: 0),
      'title': '체육',
    },
    {
      'day': 2,
      'start': const TimeOfDay(hour: 17, minute: 0),
      'end': const TimeOfDay(hour: 18, minute: 0),
      'title': '미술',
    },
    {
      'day': 1,
      'start': const TimeOfDay(hour: 20, minute: 0),
      'end': const TimeOfDay(hour: 22, minute: 0),
      'title': '독서',
    },
    {
      'day': 3,
      'start': const TimeOfDay(hour: 10, minute: 0),
      'end': const TimeOfDay(hour: 12, minute: 0),
      'title': '프로그래밍',
    },
  ];

  Offset? dragStart;
  Offset? dragEnd;
  int? dragDayIdx;

  @override
  Widget build(BuildContext context) {
    final days = ['월', '화', '수', '목', '금'];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time2goTheme = Time2GoTheme.of(context);
    final blockColors = time2goTheme.blockColors;
    final gridColor = time2goTheme.gridColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableHeight = constraints.maxHeight;
          final hourRowHeight = ((tableHeight - 40) / 24).toDouble();
          final tableWidth = constraints.maxWidth;
          final timeLabelWidth = 48.0;
          final dayColWidth =
              ((tableWidth - timeLabelWidth) / days.length).toDouble();
          final titleRowHeight = 36.0;
          final tableBorderWidth = 1.2;
          final yOffset = titleRowHeight + tableBorderWidth + 8.0;

          return GestureDetector(
            onPanStart: (details) {
              final local = details.localPosition;
              if (local.dx > timeLabelWidth) {
                final dayIdx = ((local.dx - timeLabelWidth) ~/ dayColWidth)
                    .clamp(0, days.length - 1);
                setState(() {
                  dragStart = local;
                  dragDayIdx = dayIdx;
                  dragEnd = null;
                });
              }
            },
            onPanUpdate: (details) {
              if (dragStart != null) {
                setState(() {
                  dragEnd = details.localPosition;
                });
              }
            },
            onPanEnd: (details) {
              if (dragStart != null && dragEnd != null && dragDayIdx != null) {
                final startY = dragStart!.dy - yOffset;
                final endY = dragEnd!.dy - yOffset;
                final startHour =
                    (startY / hourRowHeight).clamp(0, 23.0).round();
                final endHour = (endY / hourRowHeight).clamp(0, 23.0).round();
                final hour1 = startHour < endHour ? startHour : endHour;
                final hour2 = startHour < endHour ? endHour : startHour;
                final newStart = hour1;
                final newEnd = hour2 + 1;
                setState(() {
                  // 기존 블록 분할/삭제 처리
                  List<Map<String, dynamic>> newSchedules = [];
                  for (final s in schedules) {
                    if (s['day'] != dragDayIdx) {
                      newSchedules.add(s);
                      continue;
                    }
                    final sStart = (s['start'] as TimeOfDay).hour;
                    final sEnd = (s['end'] as TimeOfDay).hour;
                    if (sEnd <= newStart || sStart >= newEnd) {
                      newSchedules.add(s);
                      continue;
                    }
                    if (sStart < newStart) {
                      newSchedules.add({
                        'day': dragDayIdx,
                        'start': TimeOfDay(hour: sStart, minute: 0),
                        'end': TimeOfDay(hour: newStart, minute: 0),
                        'title': s['title'],
                      });
                    }
                    if (sEnd > newEnd) {
                      newSchedules.add({
                        'day': dragDayIdx,
                        'start': TimeOfDay(hour: newEnd, minute: 0),
                        'end': TimeOfDay(hour: sEnd, minute: 0),
                        'title': s['title'],
                      });
                    }
                  }
                  newSchedules.add({
                    'day': dragDayIdx,
                    'start': TimeOfDay(hour: newStart, minute: 0),
                    'end': TimeOfDay(hour: newEnd, minute: 0),
                    'title': '새 일정',
                  });
                  schedules = newSchedules;
                  dragStart = null;
                  dragEnd = null;
                  dragDayIdx = null;
                });
              } else {
                setState(() {
                  dragStart = null;
                  dragEnd = null;
                  dragDayIdx = null;
                });
              }
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: gridColor, width: 1),
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Table(
                      columnWidths: {
                        0: FixedColumnWidth(timeLabelWidth),
                        for (int i = 1; i <= days.length; i++)
                          i: FixedColumnWidth(dayColWidth),
                      },
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: gridColor, width: 1),
                      ),
                      children: _buildTableRows(
                        days,
                        hourRowHeight,
                        colorScheme,
                        textTheme,
                        gridColor,
                      ),
                    ),
                  ),
                ),
                for (int i = 0; i < 24; i++)
                  Positioned(
                    left: 0,
                    top: yOffset + i * hourRowHeight,
                    width: timeLabelWidth - 2,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        i.toString(),
                        style:
                            textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ) ??
                            TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                for (int idx = 0; idx < schedules.length; idx++)
                  (() {
                    final s = schedules[idx];
                    final dayIdx = s['day'] as int;
                    final start = s['start'] as TimeOfDay;
                    final end = s['end'] as TimeOfDay;
                    final gridYOffset = yOffset;
                    final top =
                        gridYOffset +
                        (start.hour + start.minute / 60.0) * hourRowHeight;
                    final height =
                        ((end.hour + end.minute / 60.0) -
                            (start.hour + start.minute / 60.0)) *
                        hourRowHeight;
                    final gridXOffset = timeLabelWidth + 1.2;
                    final color = blockColors[idx % blockColors.length];
                    return Positioned(
                      left: gridXOffset + dayIdx * dayColWidth,
                      top: top,
                      width: dayColWidth,
                      height: height,
                      child: ScheduleBlock(
                        title: s['title'] as String,
                        start: start,
                        end: end,
                        color: color,
                      ),
                    );
                  })(),
                if (dragStart != null && dragEnd != null && dragDayIdx != null)
                  (() {
                    final startY = dragStart!.dy - yOffset;
                    final endY = dragEnd!.dy - yOffset;
                    final startHour =
                        (startY / hourRowHeight).clamp(0, 23.0).round();
                    final endHour =
                        (endY / hourRowHeight).clamp(0, 23.0).round();
                    final hour1 = startHour < endHour ? startHour : endHour;
                    final hour2 = startHour < endHour ? endHour : startHour;
                    final top = yOffset + hour1 * hourRowHeight;
                    final height = (hour2 - hour1 + 1) * hourRowHeight;
                    final left =
                        timeLabelWidth + 1.2 + dragDayIdx! * dayColWidth;
                    return Positioned(
                      left: left,
                      top: top,
                      width: dayColWidth,
                      height: height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withAlpha(76),
                        ),
                      ),
                    );
                  })(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<TableRow> _buildTableRows(
    List<String> days,
    double hourRowHeight,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color gridColor,
  ) {
    final List<TableRow> rows = [];

    rows.add(
      TableRow(
        children: [
          SizedBox(height: 36, width: 48),
          for (final d in days)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  d,
                  style:
                      textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.primary,
                      ),
                ),
              ),
            ),
        ],
      ),
    );

    for (int h = 0; h < 24; h++) {
      rows.add(
        TableRow(
          children: [
            SizedBox(height: hourRowHeight),
            for (int d = 0; d < days.length; d++)
              SizedBox(height: hourRowHeight),
          ],
        ),
      );
    }
    return rows;
  }
}
