import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time2go/model/schedule_model.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:time2go/model/firebase_store_helper.dart';

class MeetMember {
  final String uid;
  final String displayName;
  final Color color;
  final List<ScheduleModel> schedules;

  MeetMember({
    required this.uid,
    required this.displayName,
    required this.color,
    required this.schedules,
  });
}

class MeetViewModel extends ChangeNotifier {
  final String meetId;
  final Color myColor;
  final FirebaseFirestore firestore;
  late final MeetStore store;
  void Function(String)? showSnack;

  bool isLoading = false;
  String? errorMessage;
  List<MeetMember> members = [];

  MeetViewModel({
    required this.meetId,
    required this.myColor,
    FirebaseFirestore? firestore,
    this.showSnack,
  }) : firestore = firestore ?? FirebaseFirestore.instance {
    store = MeetStore(this.firestore);
  }

  Future<void> loadMembersAndSchedules() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    showSnack?.call("멤버/시간표 불러오기 시작");
    try {
      // 1) rooms/{meetId} 문서의 members 배열 읽기
      final membersArray = await store.getRoomMembersArray(meetId);
      final blockColors = Time2GoTheme.light.blockColors;
      int colorIdx = 0;
      final List<MeetMember> loadedMembers = [];

      for (final entry in membersArray) {
        final memberRef = entry['member'];
        if (memberRef is! DocumentReference) continue;
        final uid = memberRef.id;

        // rooms 배열에 캐시된 표시값
        final fallbackName = (entry['displayName'] as String?) ?? '익명';
        final rawColor = entry['color'];

        // 색상 파싱 (#RRGGBB 또는 int). 첫 멤버는 내 색을 우선 적용
        Color color;
        if (rawColor is String && rawColor.startsWith('#')) {
          final hex = rawColor.substring(1);
          final n = int.parse(hex, radix: 16);
          final argb = hex.length == 6 ? (0xFF000000 | n) : n;
          color = Color(argb);
        } else if (rawColor is int) {
          color = Color(rawColor);
        } else {
          color =
              (colorIdx == 0
                  ? myColor
                  : blockColors[colorIdx % blockColors.length]);
        }
        colorIdx++;

        // 2) 루트 members/{uid} 문서에서 blocks 읽기
        final memberDoc = await store.getMemberOnce(uid);
        final displayName = memberDoc?.displayName ?? fallbackName;

        List<ScheduleModel> schedules = [];
        if (memberDoc != null && memberDoc.blocks.isNotEmpty) {
          schedules =
              memberDoc.blocks
                  .map(
                    (b) => ScheduleModel(
                      day: b.start.weekday,
                      start: TimeOfDay(
                        hour: b.start.hour,
                        minute: b.start.minute,
                      ),
                      end: TimeOfDay(hour: b.end.hour, minute: b.end.minute),
                      title: b.title,
                      color: color,
                    ),
                  )
                  .toList();
        }

        loadedMembers.add(
          MeetMember(
            uid: uid,
            displayName: displayName,
            color: color,
            schedules: schedules,
          ),
        );
      }

      showSnack?.call("멤버 ${loadedMembers.length}명 불러오기 완료");
      members = loadedMembers;
    } catch (e) {
      errorMessage = '미트 멤버/시간표 불러오기 실패: $e';
      showSnack?.call(errorMessage!);
    } finally {
      isLoading = false;
      showSnack?.call("멤버/시간표 불러오기 종료");
      notifyListeners();
    }
  }

  List<ScheduleModel> get mergedSchedules {
    // Flatten all members' schedules, coloring by member
    List<ScheduleModel> all = [];
    for (final m in members) {
      for (final s in m.schedules) {
        all.add(s.copyWith(color: m.color));
      }
    }
    return all;
  }

  // Optionally: Save merged timetable to Firestore (if needed)
  Future<void> saveMergedTimetable() async {
    // Implement if you want to persist the merged timetable
  }
}
