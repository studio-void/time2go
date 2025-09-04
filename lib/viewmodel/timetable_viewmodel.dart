import 'package:flutter/material.dart';
import 'package:time2go/model/firebase_store_helper.dart';
import 'package:time2go/theme/time2go_theme.dart';
import '../model/schedule_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

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

List<ScheduleModel> mockup = [
  ScheduleModel(
    day: 0,
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 11, minute: 0),
    title: '수학',
    color: Time2GoTheme.light.blockColors[0],
  ),
  ScheduleModel(
    day: 2,
    start: TimeOfDay(hour: 13, minute: 0),
    end: TimeOfDay(hour: 15, minute: 0),
    title: '과학 실험',
    color: Time2GoTheme.light.blockColors[1],
  ),
  ScheduleModel(
    day: 4,
    start: TimeOfDay(hour: 18, minute: 0),
    end: TimeOfDay(hour: 20, minute: 0),
    title: '동아리',
    color: Time2GoTheme.light.blockColors[2],
  ),
  ScheduleModel(
    day: 1,
    start: TimeOfDay(hour: 8, minute: 0),
    end: TimeOfDay(hour: 10, minute: 0),
    title: '영어',
    color: Time2GoTheme.light.blockColors[3],
  ),
  ScheduleModel(
    day: 3,
    start: TimeOfDay(hour: 15, minute: 0),
    end: TimeOfDay(hour: 17, minute: 0),
    title: '음악',
    color: Time2GoTheme.light.blockColors[4],
  ),
  ScheduleModel(
    day: 0,
    start: TimeOfDay(hour: 12, minute: 0),
    end: TimeOfDay(hour: 13, minute: 0),
    title: '체육',
    color: Time2GoTheme.light.blockColors[5],
  ),
  ScheduleModel(
    day: 2,
    start: TimeOfDay(hour: 17, minute: 0),
    end: TimeOfDay(hour: 18, minute: 0),
    title: '미술',
    color: Time2GoTheme.light.blockColors[6],
  ),
  ScheduleModel(
    day: 1,
    start: TimeOfDay(hour: 20, minute: 0),
    end: TimeOfDay(hour: 22, minute: 0),
    title: '독서',
    color: Time2GoTheme.light.blockColors[7],
  ),
  ScheduleModel(
    day: 3,
    start: TimeOfDay(hour: 10, minute: 0),
    end: TimeOfDay(hour: 12, minute: 0),
    title: '프로그래밍',
    color: Time2GoTheme.light.blockColors[0],
  ),
];

class TimetableViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  /// UI-layer can assign this to show SnackBars.
  /// Example in screen: viewModel.showSnack = (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  void Function(String message)? showSnack;

  MeetStore get _store => MeetStore(FirebaseFirestore.instance);

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: const [
      'email',
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
  );

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<GoogleSignInAccount?> ensureGoogleAccount() async {
    GoogleSignInAccount? gUser = googleSignIn.currentUser;
    gUser ??= await googleSignIn.signInSilently();
    gUser ??= await googleSignIn.signIn();
    return gUser;
  }

  Future<User?> signInWithGoogleAndFirebase() async {
    final gUser = await ensureGoogleAccount();
    if (gUser == null) return null;
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return current;
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

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Attempt to sign out Google session as well (non-fatal if not signed in)
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      showSnack?.call('로그아웃했어요.');
    } catch (e) {
      showSnack?.call('로그아웃 실패: $e');
    } finally {
      // Rebuild UI to reflect new auth state
      notifyListeners();
    }
  }

  DateTime _mondayOfThisWeekLocal(DateTime now) {
    // Flutter DateTime.weekday: Mon=1..Sun=7; our grid uses Mon=0..Sun=6
    final today0 = DateTime(now.year, now.month, now.day);
    final diffToMon = (today0.weekday - DateTime.monday);
    return today0.subtract(Duration(days: diffToMon));
  }

  DateTime _dateForDayHour(int day, int hour, {int minute = 0}) {
    final baseMon = _mondayOfThisWeekLocal(DateTime.now());
    final d = baseMon.add(Duration(days: day));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  String _colorToHex(Color c) {
    String two(int v) => v.toRadixString(16).padLeft(2, '0');
    return '#${two(c.red)}${two(c.green)}${two(c.blue)}';
  }

  Color _hexToColor(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) {
      final r = int.parse(h.substring(0, 2), radix: 16);
      final g = int.parse(h.substring(2, 4), radix: 16);
      final b = int.parse(h.substring(4, 6), radix: 16);
      return Color.fromARGB(255, r, g, b);
    } else if (h.length == 8) {
      final a = int.parse(h.substring(0, 2), radix: 16);
      final r = int.parse(h.substring(2, 4), radix: 16);
      final g = int.parse(h.substring(4, 6), radix: 16);
      final b = int.parse(h.substring(6, 8), radix: 16);
      return Color.fromARGB(a, r, g, b);
    }
    // Fallback: random-ish but stable color for malformed hex
    return Colors.grey;
  }

  Future<void> importGoogleCalendar(BuildContext context) async {
    isLoading = true;
    showSnack?.call('구글 캘린더에서 일정을 불러오는 중...');
    errorMessage = null;
    notifyListeners();
    try {
      final user = await signInWithGoogleAndFirebase();
      if (user == null) {
        errorMessage = '로그인이 취소되었어요.';
        isLoading = false;
        notifyListeners();
        return;
      }
      final account = await ensureGoogleAccount();
      if (account == null) {
        errorMessage = '구글 로그인이 필요해요.';
        isLoading = false;
        notifyListeners();
        return;
      }
      final authHeaders = await account.authHeaders;
      final authClient = _GoogleAuthClient(authHeaders);
      try {
        final calendarApi = calendar.CalendarApi(authClient);
        final calendarList = await calendarApi.calendarList.list();
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
            timeMax: DateTime.now().toUtc().add(const Duration(days: 7)),
          );
          allEvents.addAll(events.items ?? []);
        }
        final List<calendar.Event> filtered = [
          for (final e in allEvents)
            if (e.start?.dateTime != null && e.end?.dateTime != null) e,
        ];
        final List<Color> blockColors = Time2GoTheme.light.blockColors;
        final List<ScheduleModel> events = [];
        for (int i = 0; i < filtered.length; i++) {
          final item = filtered[i];
          final DateTime? startDT = item.start?.dateTime?.toLocal();
          final DateTime? endDT = item.end?.dateTime?.toLocal();
          if (startDT == null || endDT == null) continue;
          final weekday = startDT.weekday - 1;
          if (weekday < 0 || weekday > 4) continue;
          events.add(
            ScheduleModel(
              day: weekday,
              start: TimeOfDay(hour: startDT.hour, minute: startDT.minute),
              end: TimeOfDay(hour: endDT.hour, minute: endDT.minute),
              title: item.summary ?? '구글 일정',
              color: blockColors[i % blockColors.length],
            ),
          );
        }
        await addGoogleCalendarEvents(events);
        showSnack?.call('구글 일정 ${events.length}건 추가');
      } finally {
        authClient.close();
      }
    } catch (e) {
      errorMessage = '구글 캘린더 가져오기 실패: $e';
      showSnack?.call(errorMessage!);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _keyFromParts(int weekday, int sh, int sm, int eh, int em) =>
      '$weekday-${sh.toString().padLeft(2, '0')}${sm.toString().padLeft(2, '0')}-${eh.toString().padLeft(2, '0')}${em.toString().padLeft(2, '0')}';

  /// DB에서 불러온 블록들을 (요일+시작/끝 시:분) 기준으로 **마지막 레코드만** 유지하여 중복을 제거한다.
  Future<void> loadSchedulesFromDatabase(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnack?.call('로그인이 필요해요.');
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final store = MeetStore(FirebaseFirestore.instance);
      final blocks = await store.getBlocks(user.uid);

      // Clear and rebuild from DB snapshot WITHOUT persisting back.
      final Map<String, ScheduleModel> byKey = {};
      for (final b in blocks) {
        final start = b.start; // 그대로 사용 (timezone 변환 안함)
        final end = b.end;
        final weekday = start.weekday - 1; // Mon=1 -> 0
        if (weekday < 0 || weekday > 6) continue;

        final title = b.title.trim().isEmpty ? '일정' : b.title.trim();
        final Color color =
            b.colorHex.isNotEmpty
                ? _hexToColor(b.colorHex)
                : Time2GoTheme.light.blockColors[0];

        final key = _keyFromParts(
          weekday,
          start.hour,
          start.minute,
          end.hour,
          end.minute,
        );

        // 마지막으로 본(가장 최신이라고 가정) 레코드로 덮어쓰기
        byKey[key] = ScheduleModel(
          day: weekday,
          start: TimeOfDay(hour: start.hour, minute: start.minute),
          end: TimeOfDay(hour: end.hour, minute: end.minute),
          title: title,
          color: color,
        );
      }

      final loaded = byKey.values.toList(growable: false);
      _schedules = loaded;
      showSnack?.call('데이터베이스에서 일정 불러오기 완료 (${loaded.length}개)');
    } catch (e) {
      errorMessage = '데이터베이스에서 일정 불러오기 실패: $e';
      showSnack?.call(errorMessage!);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<ScheduleModel> _schedules = [];

  List<ScheduleModel> get schedules => List.unmodifiable(_schedules);

  Future<void> addGoogleCalendarEvents(List<ScheduleModel> events) async {
    // 1) UI 갱신 (growable 보장)
    _schedules = List.of(_schedules)..addAll(events);
    notifyListeners();

    // 2) 비동기 저장 (구글 캘린더에서 가져온 항목으로 표시)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      () async {
        try {
          await _ensureMemberExists(user.uid);
          for (final e in events) {
            await _persistBlock(e, state: 'yes', source: 'import-google');
          }
          showSnack?.call('구글 일정 DB 저장 완료');
        } catch (e) {
          showSnack?.call('구글 일정 저장 실패: $e');
        }
      }();
    } else {
      showSnack?.call('로그인되어 있지 않아 구글 일정이 로컬에만 반영됐어요');
    }
  }

  /// Adds a new user-created block into the grid, splitting overlaps.
  /// NOTE: This method **persists** to the database. Do NOT use when reconstructing
  /// UI from DB (e.g., in loadSchedulesFromDatabase).
  void addOrSplitBlock(int day, int startHour, int endHour, String title) {
    final newStart = startHour;
    final newEnd = endHour;
    final colors = Time2GoTheme.light.blockColors;
    final Color pickedColor = colors[_schedules.length % colors.length];
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
            color: s.color,
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
            color: s.color,
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
        color: pickedColor,
      ),
    );
    _schedules = newList;
    showSnack?.call('일정 추가: $title');

    // Persist to Firestore (best-effort, keep UI responsive)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      () async {
        try {
          await _ensureMemberExists(user.uid);
          final startDT = _dateForDayHour(day, newStart, minute: 0);
          final endDT = _dateForDayHour(day, newEnd, minute: 0);
          await _store.addMemberBlock(
            uid: user.uid,
            start: startDT,
            end: endDT,
            title: title,
            colorHex: _colorToHex(pickedColor),
            state: 'yes',
            source: 'manual',
          );
          showSnack?.call('저장 완료: $title');
        } catch (e) {
          showSnack?.call('저장 실패: $e');
        }
      }();
    } else {
      showSnack?.call('로그인되어 있지 않아 로컬에서만 추가되었어요');
    }

    notifyListeners();
  }

  /// Delete a schedule by index. If out of range, no-op.
  Future<void> deleteSchedule(int index) async {
    if (index < 0 || index >= _schedules.length) {
      showSnack?.call('삭제 실패: 잘못된 인덱스');
      return;
    }
    final removed = _schedules[index];
    _schedules = List.of(_schedules)..removeAt(index);
    notifyListeners();
    showSnack?.call('일정 삭제: ${removed.title}');
    try {
      await _persistBlock(removed, state: 'deleted', source: 'manual-delete');
    } catch (e) {
      showSnack?.call('DB 반영 실패: $e');
    }
  }

  /// Recolor a schedule and persist.
  Future<void> recolorSchedule(int index, Color newColor) async {
    if (index < 0 || index >= _schedules.length) {
      showSnack?.call('색 변경 실패: 잘못된 인덱스');
      return;
    }
    final s = _schedules[index];
    final updated = ScheduleModel(
      day: s.day,
      start: s.start,
      end: s.end,
      title: s.title,
      color: newColor,
    );
    _schedules = List.of(_schedules);
    _schedules[index] = updated;
    notifyListeners();
    showSnack?.call('색 변경 완료: ${s.title}');
    try {
      await _persistDelete(s); // 원본 삭제 마킹
      await _persistBlock(updated, state: 'yes', source: 'update-color');
    } catch (e) {
      showSnack?.call('DB 반영 실패: $e');
    }
  }

  /// Rename a schedule and persist.
  Future<void> renameSchedule(int index, String newTitle) async {
    if (index < 0 || index >= _schedules.length) {
      showSnack?.call('이름 변경 실패: 잘못된 인덱스');
      return;
    }
    final s = _schedules[index];
    final updated = ScheduleModel(
      day: s.day,
      start: s.start,
      end: s.end,
      title: newTitle,
      color: s.color,
    );
    _schedules = List.of(_schedules);
    _schedules[index] = updated;
    notifyListeners();
    showSnack?.call('이름 변경 완료: ${newTitle}');
    try {
      await _persistDelete(s); // 원본 삭제 마킹
      await _persistBlock(updated, state: 'yes', source: 'update-title');
    } catch (e) {
      showSnack?.call('DB 반영 실패: $e');
    }
  }

  Future<void> _ensureMemberExists(String uid) async {
    final doc = FirebaseFirestore.instance.collection('members').doc(uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _persistDelete(ScheduleModel s) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnack?.call('로그인되어 있지 않아 로컬에서만 반영되었어요');
      return;
    }
    await _ensureMemberExists(user.uid);
    try {
      final startDT = _dateForDayHour(
        s.day,
        s.start.hour,
        minute: s.start.minute,
      );
      final endDT = _dateForDayHour(s.day, s.end.hour, minute: s.end.minute);
      await _store.addMemberBlock(
        uid: user.uid,
        start: startDT,
        end: endDT,
        title: s.title,
        colorHex: _colorToHex(s.color),
        state: 'deleted',
        source: 'update-replace',
      );
    } catch (e) {
      showSnack?.call('DB 삭제 마킹 실패: $e');
      rethrow;
    }
  }

  /// Best-effort persistence for a single schedule snapshot.
  /// Writes a record with the given state/source; downstream can treat
  /// state == 'deleted' as removal.
  Future<void> _persistBlock(
    ScheduleModel s, {
    required String state,
    required String source,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnack?.call('로그인되어 있지 않아 로컬에서만 반영되었어요');
      return;
    }
    await _ensureMemberExists(user.uid);
    try {
      final startDT = _dateForDayHour(
        s.day,
        s.start.hour,
        minute: s.start.minute,
      );
      final endDT = _dateForDayHour(s.day, s.end.hour, minute: s.end.minute);
      await _store.addMemberBlock(
        uid: user.uid,
        start: startDT,
        end: endDT,
        title: s.title,
        colorHex: _colorToHex(s.color),
        state: state,
        source: source,
      );
    } catch (e) {
      showSnack?.call('DB 저장 실패: $e');
      rethrow;
    }
  }
}
