import 'package:cloud_firestore/cloud_firestore.dart';

/// ─────────────────────────────────────────────────────────────────
/// Models
/// ─────────────────────────────────────────────────────────────────
class Room {
  final String id;
  final String title;
  final DateTime rangeStartUtc;
  final DateTime createdAtUtc;

  Room({
    required this.id,
    required this.title,
    required this.rangeStartUtc,
    required this.createdAtUtc,
  });

  DateTime get rangeEndUtc => rangeStartUtc.add(const Duration(days: 7));

  factory Room.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return Room(
      id: snap.id,
      title: (d['title'] as String?) ?? 'Untitled',
      rangeStartUtc: (d['rangeStart'] as Timestamp).toDate().toUtc(),
      createdAtUtc:
          ((d['createdAt'] as Timestamp?) ?? Timestamp.now()).toDate().toUtc(),
    );
  }
}

class Member {
  final String uid;
  final String displayName;
  final String? colorHex;
  final DateTime joinedAtUtc;
  final List<Block> blocks;

  Member({
    required this.uid,
    required this.displayName,
    required this.joinedAtUtc,
    required this.blocks,
    this.colorHex,
  });

  factory Member.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final raw = (d['blocks'] as List?) ?? const [];
    return Member(
      uid: snap.id,
      displayName: (d['displayName'] as String?) ?? '익명',
      colorHex: d['color'] as String?,
      joinedAtUtc:
          ((d['joinedAt'] as Timestamp?) ?? Timestamp.now()).toDate().toUtc(),
      blocks:
          raw
              .map((e) => Block.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start)),
    );
  }

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    if (colorHex != null) 'color': colorHex,
    'joinedAt': Timestamp.fromDate(joinedAtUtc),
    'blocks': blocks.map((b) => b.toMap()).toList(),
  };
}

class Block {
  final DateTime start;
  final DateTime end;
  final String state; // 'yes' | 'maybe' (필요시)
  final String source; // 'manual' | 'calendarBusy' 등
  final String title; // 제목 (옵션)
  final String colorHex; // 블록 색상 (옵션)

  Block({
    required this.start,
    required this.end,
    this.state = 'yes',
    this.source = 'manual',
    required this.title,
    required this.colorHex,
  }) : assert(!end.isBefore(start), 'end must be after start');

  factory Block.fromMap(Map<String, dynamic> m) => Block(
    start: (m['start'] as Timestamp).toDate(),
    end: (m['end'] as Timestamp).toDate(),
    state: (m['state'] as String?) ?? 'yes',
    source: (m['source'] as String?) ?? 'manual',
    title: (m['title'] as String?) ?? 'Untitled',
    colorHex: (m['color'] as String?) ?? '#000000',
  );

  Map<String, dynamic> toMap() => {
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'state': state,
    'source': source,
    'title': title,
    'color': colorHex,
  };
}

/// ─────────────────────────────────────────────────────────────────
/// Repository / Helper
/// ─────────────────────────────────────────────────────────────────
class MeetStore {
  MeetStore(this._db);
  final FirebaseFirestore _db;

  // refs
  DocumentReference<Map<String, dynamic>> roomRef(String roomId) =>
      _db.collection('rooms').doc(roomId);

  DocumentReference<Map<String, dynamic>> memberRef(String uid) =>
      _db.collection('members').doc(uid);

  /// 방 생성(없으면 생성, 있으면 merge)
  Future<void> createOrUpdateRoom({
    required String roomId,
    required String title,
    required DateTime rangeStartUtc,
  }) async {
    await roomRef(roomId).set({
      'title': title,
      'rangeStart': Timestamp.fromDate(rangeStartUtc.toUtc()),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 방 구독
  Stream<Room?> watchRoom(String roomId) {
    return roomRef(roomId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Room.fromSnap(snap);
    });
  }

  /// 멤버 목록 구독
  Stream<List<Member>> watchMembers(String roomId) {
    return roomRef(roomId).collection('members').snapshots().map((qs) {
      return qs.docs.map(Member.fromSnap).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    });
  }

  /// 방을 한 번만 읽기 (없으면 null)
  Future<Room?> getRoomOnce(String roomId) async {
    final snap = await roomRef(roomId).get();
    if (!snap.exists || snap.data() == null) return null;
    return Room.fromSnap(snap);
  }

  /// 방 입장(멤버 문서 생성/업데이트)
  Future<void> joinRoom({
    required String roomId,
    required String uid,
    required String displayName,
    String? colorHex,
  }) async {
    await memberRef(uid).set({
      'displayName': displayName,
      if (colorHex != null) 'color': colorHex,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 방이 없으면 생성 후, 멤버로 입장 처리까지 한 번에 수행
  /// 반환: created=true면 새로 생성됨, false면 기존 방
  Future<({bool created, Room room})> ensureRoomAndJoin({
    required String roomId,
    required String title,
    required DateTime rangeStartUtc,
    required String uid,
    required String displayName,
    String? colorHex,
  }) async {
    Room? outRoom;
    bool created = false;
    await _db.runTransaction((tx) async {
      final rRef = roomRef(roomId);
      final rSnap = await tx.get(rRef);
      if (!rSnap.exists) {
        created = true;
        tx.set(rRef, {
          'title': title,
          'rangeStart': Timestamp.fromDate(rangeStartUtc.toUtc()),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      // 멤버 입장 처리
      final mRef = memberRef(uid);
      tx.set(mRef, {
        'displayName': displayName,
        if (colorHex != null) 'color': colorHex,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // 최신 room 스냅을 구성
      final after = rSnap.exists ? rSnap : await tx.get(rRef);
      outRoom = Room.fromSnap(after);
    });
    return (created: created, room: outRoom!);
  }

  Future<void> ensureMembership({
    required String roomId,
    required String uid,
    String? displayName,
    String? colorHex,
  }) async {
    final mRef = memberRef(uid);
    await memberRef(uid).set({
      if (displayName != null) 'displayName': displayName,
      if (colorHex != null) 'color': colorHex,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await roomRef(roomId).set({
      'members': FieldValue.arrayUnion([
        {
          'member': mRef,
          if (displayName != null) 'displayName': displayName,
          if (colorHex != null) 'color': colorHex,
        },
      ]),
    }, SetOptions(merge: true));
  }

  /// 멤버의 blocks 읽기
  Future<List<Block>> getBlocks(String uid) async {
    final snap = await memberRef(uid).get();
    if (!snap.exists) return [];
    return Member.fromSnap(snap).blocks;
  }

  /// 블록 추가(겹치면 병합). 배열 전체 교체 전략.
  Future<void> upsertBlock({required String uid, required Block block}) async {
    await _db.runTransaction((tx) async {
      final mRef = memberRef(uid);
      final snap = await tx.get(mRef);
      final existing =
          snap.exists
              ? Member.fromSnap(snap)
              : Member(
                uid: uid,
                displayName: '익명',
                joinedAtUtc: DateTime.now().toUtc(),
                blocks: const [],
              );

      final merged = mergeBlocks([...existing.blocks, block]);
      final data =
          existing.toMap()..['blocks'] = merged.map((e) => e.toMap()).toList();
      tx.set(mRef, data, SetOptions(merge: true));
    });
  }

  /// 블록 제거(정확히 같은 구간 매치). 필요 시 근접 매치/교차 제거로 확장 가능.
  Future<void> removeBlock({required String uid, required Block block}) async {
    await _db.runTransaction((tx) async {
      final mRef = memberRef(uid);
      final snap = await tx.get(mRef);
      if (!snap.exists) return;
      final existing = Member.fromSnap(snap);

      final next =
          existing.blocks
              .where(
                (b) =>
                    !(b.start == block.start &&
                        b.end == block.end &&
                        b.state == block.state &&
                        b.source == block.source),
              )
              .toList();

      tx.set(mRef, {
        'blocks': next.map((e) => e.toMap()).toList(),
      }, SetOptions(merge: true));
    });
  }

  /// 여러 블록을 한꺼번에 설정(드래그 편집 결과 등)
  Future<void> setBlocks({
    required String uid,
    required List<Block> blocks,
    String? displayName,
    String? colorHex,
  }) async {
    final merged = mergeBlocks(blocks);
    await memberRef(uid).set({
      if (displayName != null) 'displayName': displayName,
      if (colorHex != null) 'color': colorHex,
      'blocks': merged.map((e) => e.toMap()).toList(),
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 겹치거나 인접(1분 이내)하며 같은 state인 블록 병합
  static List<Block> mergeBlocks(List<Block> list) {
    if (list.isEmpty) return list;
    final sorted = [...list]..sort((a, b) => a.start.compareTo(b.start));
    final out = <Block>[];
    for (final cur in sorted) {
      if (out.isEmpty) {
        out.add(cur);
        continue;
      }
      final last = out.last;
      final touches =
          !cur.start.isAfter(last.end.add(const Duration(minutes: 1)));
      final sameMeta =
          cur.state == last.state &&
          cur.source == last.source &&
          cur.title == last.title &&
          cur.colorHex == last.colorHex;
      if (touches && sameMeta) {
        if (cur.end.isAfter(last.end)) {
          out[out.length - 1] = Block(
            start: last.start,
            end: cur.end,
            state: last.state,
            source: last.source,
            title: last.title,
            colorHex: last.colorHex,
          );
        }
      } else {
        out.add(cur);
      }
    }
    return out;
  }

  Future<void> addMemberBlock({
    required String uid,
    required DateTime start,
    required DateTime end,
    required String title,
    required String colorHex,
    String state = 'yes',
    String source = 'manual',
  }) async {
    await upsertBlock(
      uid: uid,
      block: Block(
        start: start,
        end: end,
        state: state,
        source: source,
        title: title,
        colorHex: colorHex,
      ),
    );
  }
}
