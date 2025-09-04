import 'package:flutter/material.dart';
import 'package:time2go/model/schedule_model.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:time2go/view/widgets/schedule_block.dart';

/// 통합 캘린더 그리드
/// - drag로 블록 추가 기능을 on/off 할 수 있음(allowDrag)
/// - 상단 제목/요일, 시간축, 그리드, 블록 렌더링 등 공통 UI 캡슐화
class CalendarGrid extends StatefulWidget {
  final List<String> days;
  final List<ScheduleModel> schedules;
  final List<Color> blockColors;
  final Color gridColor;
  final bool allowDrag;
  final void Function(int day, int startHour, int endHour)? onDragCreate;
  final void Function(int index)? onDeleteRequest;
  final void Function(int index, String newTitle)? onRenameRequest;
  final void Function(int index, Color newColor)? onRecolorRequest;

  const CalendarGrid({
    super.key,
    this.days = const ['월', '화', '수', '목', '금'],
    required this.schedules,
    required this.blockColors,
    required this.gridColor,
    this.allowDrag = true,
    this.onDragCreate,
    this.onDeleteRequest,
    this.onRenameRequest,
    this.onRecolorRequest,
  });

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  Offset? dragStart;
  Offset? dragEnd;
  int? dragDayIdx;

  List<TableRow> _buildTableRows(
    List<String> days,
    double hourRowHeight,
    Time2GoTheme time2goTheme,
    TextTheme textTheme,
    Color gridColor,
  ) {
    final List<TableRow> rows = [];

    rows.add(
      TableRow(
        children: [
          const SizedBox(height: 36, width: 48),
          for (final d in days)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  d,
                  style:
                      textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: time2goTheme.foregroundColor,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: time2goTheme.foregroundColor,
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

  Future<void> _showContextMenuAt(Offset globalPosition, int index) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: const [
        PopupMenuItem<String>(value: 'rename', child: Text('이름 변경')),
        PopupMenuItem<String>(value: 'color', child: Text('색 변경')),
        PopupMenuItem<String>(value: 'delete', child: Text('삭제')),
      ],
    );

    if (selected == null) return;

    if (selected == 'delete') {
      if (widget.onDeleteRequest != null) widget.onDeleteRequest!(index);
      return;
    }

    if (selected == 'rename') {
      final currentTitle = widget.schedules[index].title;
      final newTitle = await _promptRename(currentTitle);
      if (newTitle != null && newTitle.trim().isNotEmpty) {
        widget.onRenameRequest?.call(index, newTitle.trim());
      }
      return;
    }

    if (selected == 'color') {
      final picked = await _promptPickColor(globalPosition);
      if (picked != null) {
        widget.onRecolorRequest?.call(index, picked);
      }
      return;
    }
  }

  Future<String?> _promptRename(String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('이름 변경'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '새 이름을 입력하세요'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<Color?> _promptPickColor(Offset at) async {
    // Use a simple popup menu with the provided blockColors as options.
    final menuItems =
        widget.blockColors
            .map(
              (c) => PopupMenuItem<Color>(
                value: c,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            )
            .toList();

    return showMenu<Color>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: menuItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time2goTheme = Time2GoTheme.of(context);
    final gridColor = widget.gridColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final schedules = widget.schedules;
          final tableHeight = constraints.maxHeight;
          final hourRowHeight = ((tableHeight - 40) / 24).toDouble();
          final tableWidth = constraints.maxWidth;
          final timeLabelWidth = 48.0;
          final dayColWidth =
              ((tableWidth - timeLabelWidth) / days.length).toDouble();
          final titleRowHeight = 36.0;
          final tableBorderWidth = 1.2;
          final yOffset = titleRowHeight + tableBorderWidth + 8.0;

          Widget gridStack() => Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: gridColor, width: 1),
                  borderRadius: BorderRadius.circular(16),
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
                      time2goTheme,
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
                  final int dayIdx = s.day;
                  final TimeOfDay start = s.start;
                  final TimeOfDay end = s.end;
                  final gridYOffset = yOffset;
                  final top =
                      gridYOffset +
                      (start.hour + start.minute / 60.0) * hourRowHeight;
                  final height =
                      ((end.hour + end.minute / 60.0) -
                          (start.hour + start.minute / 60.0)) *
                      hourRowHeight;
                  final gridXOffset = timeLabelWidth + 1.2;
                  final Color color = s.color; // use model's color, not theme

                  return Positioned(
                    left: gridXOffset + dayIdx * dayColWidth,
                    top: top,
                    width: dayColWidth,
                    height: height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onSecondaryTapDown: (details) async {
                        await _showContextMenuAt(details.globalPosition, idx);
                      },
                      onLongPressStart: (details) async {
                        await _showContextMenuAt(details.globalPosition, idx);
                      },
                      child: ScheduleBlock(
                        title: s.title,
                        start: start,
                        end: end,
                        color: color, // use model's color, not theme
                      ),
                    ),
                  );
                })(),
              if (widget.allowDrag &&
                  dragStart != null &&
                  dragEnd != null &&
                  dragDayIdx != null)
                (() {
                  final startY = dragStart!.dy - yOffset;
                  final endY = dragEnd!.dy - yOffset;
                  final startHour =
                      (startY / hourRowHeight).clamp(0, 23.0).round();
                  final endHour = (endY / hourRowHeight).clamp(0, 23.0).round();
                  final hour1 = startHour < endHour ? startHour : endHour;
                  final hour2 = startHour < endHour ? endHour : startHour;
                  final top = yOffset + hour1 * hourRowHeight;
                  final height = (hour2 - hour1 + 1) * hourRowHeight;
                  final left = timeLabelWidth + 1.2 + dragDayIdx! * dayColWidth;
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
          );

          if (!widget.allowDrag) {
            return gridStack();
          }

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
                if (widget.onDragCreate != null) {
                  widget.onDragCreate!(dragDayIdx!, newStart, newEnd);
                }
                setState(() {
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
            child: gridStack(),
          );
        },
      ),
    );
  }
}
