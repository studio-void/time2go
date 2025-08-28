import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:time2go/view/widgets/schedule_block.dart';
import 'package:time2go/viewmodel/timetable_viewmodel.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  TimetableViewModel viewModel = TimetableViewModel();
  Offset? dragStart;
  Offset? dragEnd;
  int? dragDayIdx;
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const [
      'email',
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
  );

  Future<GoogleSignInAccount?> _ensureGoogleAccount() async {
    GoogleSignInAccount? gUser = _googleSignIn.currentUser;
    gUser ??= await _googleSignIn.signInSilently();
    gUser ??= await _googleSignIn.signIn();
    return gUser; // may be null if user cancels
  }

  Future<User?> _signInWithGoogleAndFirebase() async {
    // Always ensure we have a Google account first (needed for Calendar API)
    final gUser = await _ensureGoogleAccount();
    if (gUser == null) return null; // user cancelled

    // If already signed in to Firebase, reuse it; otherwise link Google to Firebase
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      return current;
    }

    final gAuth = await gUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: gAuth.idToken,
      accessToken: gAuth.accessToken,
    );
    final userCred = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    return userCred.user;
  }

  // 구글 캘린더에서 일정을 가져와 timetable에 추가하는 함수 (실제 구현)
  Future<void> _importGoogleCalendar() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // 1) Ensure Google Sign-In & FirebaseAuth session
      final user = await _signInWithGoogleAndFirebase();
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 취소되었어요.')));
        return;
      }

      // 2) Build an authenticated client for googleapis using the Google account
      final account = await _ensureGoogleAccount();
      if (account == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('구글 로그인이 필요해요.')));
        return;
      }
      final authHeaders = await account.authHeaders;
      final authClient = _GoogleAuthClient(authHeaders);

      try {
        // 3) Call Calendar API
        final calendarApi = calendar.CalendarApi(authClient);

        final calendarList = await calendarApi.calendarList.list();
        for (var cal in calendarList.items ?? []) {
          debugPrint('캘린더 이름=${cal.summary}, id=${cal.id}');
        }

        final List<calendar.Event> allEvents = [];
        for (final cal in calendarList.items ?? []) {
          final id = cal.id;
          if (id == null) continue;
          final events = await calendarApi.events.list(
            id,
            maxResults: 50,
            singleEvents: true,
            orderBy: 'startTime',
            timeMin: DateTime.now().toUtc(),
          );
          allEvents.addAll(events.items ?? []);
        }

        final List<calendar.Event> filtered = [
          for (final e in allEvents)
            if (e.start?.dateTime != null && e.end?.dateTime != null) e,
        ];

        // 4) Convert to timetable format (Mon~Fri)
        final List<Map<String, dynamic>> events = [];
        for (final item in filtered) {
          final DateTime? startDT = item.start?.dateTime?.toLocal();
          final DateTime? endDT = item.end?.dateTime?.toLocal();
          if (startDT == null || endDT == null) continue;

          final weekday = startDT.weekday - 1; // Mon=0..Sun=6
          if (weekday < 0 || weekday > 4) continue;

          events.add({
            'day': weekday,
            'startHour': startDT.hour,
            'startMinute': startDT.minute,
            'endHour':
                endDT.hour == 0 && endDT.isAfter(startDT) ? 24 : endDT.hour,
            'endMinute': endDT.minute,
            'title': item.summary ?? '구글 일정',
          });
        }

        // 5) Update view model
        viewModel.addGoogleCalendarEvents(events);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구글 캘린더에서 ${events.length}건을 가져왔어요.')),
        );
      } finally {
        authClient.close();
      }
    } catch (e) {
      debugPrint('구글 캘린더 가져오기 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구글 캘린더 가져오기 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final days = ['월', '화', '수', '목', '금'];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time2goTheme = Time2GoTheme.of(context);
    final blockColors = time2goTheme.blockColors;
    final gridColor = time2goTheme.gridColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time2Go'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: _importGoogleCalendar,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final schedules = viewModel.schedules;
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
                      final dayIdx = ((local.dx - timeLabelWidth) ~/
                              dayColWidth)
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
                    if (dragStart != null &&
                        dragEnd != null &&
                        dragDayIdx != null) {
                      final startY = dragStart!.dy - yOffset;
                      final endY = dragEnd!.dy - yOffset;
                      final startHour =
                          (startY / hourRowHeight).clamp(0, 23.0).round();
                      final endHour =
                          (endY / hourRowHeight).clamp(0, 23.0).round();
                      final hour1 = startHour < endHour ? startHour : endHour;
                      final hour2 = startHour < endHour ? endHour : startHour;
                      final newStart = hour1;
                      final newEnd = hour2 + 1;
                      viewModel.addOrSplitBlock(
                        dragDayIdx!,
                        newStart,
                        newEnd,
                        '새 일정',
                      );
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
                          final dayIdx = s.day;
                          final start = s.start;
                          final end = s.end;
                          final gridYOffset = yOffset;
                          final top =
                              gridYOffset +
                              (start.hour + start.minute / 60.0) *
                                  hourRowHeight;
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
                              title: s.title,
                              start: start,
                              end: end,
                              color: color,
                            ),
                          );
                        })(),
                      if (dragStart != null &&
                          dragEnd != null &&
                          dragDayIdx != null)
                        (() {
                          final startY = dragStart!.dy - yOffset;
                          final endY = dragEnd!.dy - yOffset;
                          final startHour =
                              (startY / hourRowHeight).clamp(0, 23.0).round();
                          final endHour =
                              (endY / hourRowHeight).clamp(0, 23.0).round();
                          final hour1 =
                              startHour < endHour ? startHour : endHour;
                          final hour2 =
                              startHour < endHour ? endHour : startHour;
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
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// Adds Google auth headers to every request. Needed by `googleapis` package.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
