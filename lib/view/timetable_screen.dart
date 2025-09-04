import 'package:flutter/material.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:time2go/view/widgets/calendar_grid.dart';
import 'package:time2go/viewmodel/timetable_viewmodel.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  TimetableViewModel viewModel = TimetableViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_onViewModelChanged);
    viewModel.showSnack = (msg) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: Duration(seconds: 1)),
          );
        }
      });
    };
    viewModel.loadSchedulesFromDatabase(context);
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final time2goTheme = Time2GoTheme.of(context);
    final blockColors = time2goTheme.blockColors;
    final gridColor = time2goTheme.gridColor;

    return Scaffold(
      backgroundColor: Time2GoTheme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Time2GoTheme.of(context).backgroundColor,
        foregroundColor: Time2GoTheme.of(context).foregroundColor,
        title: const Text('Time2Go'),
        actions: [
          if (viewModel.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '로그아웃',
              onPressed: () => viewModel.logout(),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_download),
              tooltip: '구글 캘린더 가져오기',
              onPressed: () => viewModel.importGoogleCalendar(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          CalendarGrid(
            schedules: viewModel.schedules,
            blockColors: blockColors,
            gridColor: gridColor,
            allowDrag: true,
            onDragCreate: (day, startHour, endHour) async {
              viewModel.addOrSplitBlock(day, startHour, endHour, '새 일정');
            },
            onDeleteRequest: (index) {
              viewModel.deleteSchedule(index);
            },
            onRecolorRequest: (index, newColor) {
              viewModel.recolorSchedule(index, newColor);
            },
            onRenameRequest: (index, newTitle) {
              viewModel.renameSchedule(index, newTitle);
            },
          ),
          if (viewModel.isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  color: Time2GoTheme.of(context).foregroundColor,
                ),
              ),
            ),
          if (viewModel.errorMessage != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
