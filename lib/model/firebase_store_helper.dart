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
            ..sort((a, b) => a.startUtc.compareTo(b.startUtc)),
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
  final DateTime startUtc;
  final DateTime endUtc;
  final String state; // 'yes' | 'maybe' (필요시)
  final String source; // 'manual' | 'calendarBusy' 등

  Block({
    required this.startUtc,
    required this.endUtc,
    this.state = 'yes',
    this.source = 'manual',
  }) : assert(!endUtc.isBefore(startUtc), 'end must be after start');

  factory Block.fromMap(Map<String, dynamic> m) => Block(
    startUtc: (m['start'] as Timestamp).toDate().toUtc(),
    endUtc: (m['end'] as Timestamp).toDate().toUtc(),
    state: (m['state'] as String?) ?? 'yes',
    source: (m['source'] as String?) ?? 'manual',
  );

  Map<String, dynamic> toMap() => {
    'start': Timestamp.fromDate(startUtc),
    'end': Timestamp.fromDate(endUtc),
    'state': state,
    'source': source,
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

  DocumentReference<Map<String, dynamic>> memberRef(
    String roomId,
    String uid,
  ) => roomRef(roomId).collection('members').doc(uid);

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

  /// 방 입장(멤버 문서 생성/업데이트)
  Future<void> joinRoom({
    required String roomId,
    required String uid,
    required String displayName,
    String? colorHex,
  }) async {
    await memberRef(roomId, uid).set({
      'displayName': displayName,
      if (colorHex != null) 'color': colorHex,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 멤버의 blocks 읽기
  Future<List<Block>> getBlocks(String roomId, String uid) async {
    final snap = await memberRef(roomId, uid).get();
    if (!snap.exists) return [];
    return Member.fromSnap(snap).blocks;
  }

  /// 블록 추가(겹치면 병합). 배열 전체 교체 전략.
  Future<void> upsertBlock({
    required String roomId,
    required String uid,
    required Block block,
  }) async {
    await _db.runTransaction((tx) async {
      final mRef = memberRef(roomId, uid);
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
  Future<void> removeBlock({
    required String roomId,
    required String uid,
    required Block block,
  }) async {
    await _db.runTransaction((tx) async {
      final mRef = memberRef(roomId, uid);
      final snap = await tx.get(mRef);
      if (!snap.exists) return;
      final existing = Member.fromSnap(snap);

      final next =
          existing.blocks
              .where(
                (b) =>
                    !(b.startUtc == block.startUtc &&
                        b.endUtc == block.endUtc &&
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
    required String roomId,
    required String uid,
    required List<Block> blocks,
    String? displayName,
    String? colorHex,
  }) async {
    final merged = mergeBlocks(blocks);
    await memberRef(roomId, uid).set({
      if (displayName != null) 'displayName': displayName,
      if (colorHex != null) 'color': colorHex,
      'blocks': merged.map((e) => e.toMap()).toList(),
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 겹치거나 인접(1분 이내)하며 같은 state인 블록 병합
  static List<Block> mergeBlocks(List<Block> list) {
    if (list.isEmpty) return list;
    final sorted = [...list]..sort((a, b) => a.startUtc.compareTo(b.startUtc));
    final out = <Block>[];
    for (final cur in sorted) {
      if (out.isEmpty) {
        out.add(cur);
        continue;
      }
      final last = out.last;
      final touches =
          !cur.startUtc.isAfter(last.endUtc.add(const Duration(minutes: 1)));
      final sameState = cur.state == last.state && cur.source == last.source;
      if (touches && sameState) {
        if (cur.endUtc.isAfter(last.endUtc)) {
          out[out.length - 1] = Block(
            startUtc: last.startUtc,
            endUtc: cur.endUtc,
            state: last.state,
            source: last.source,
          );
        }
      } else {
        out.add(cur);
      }
    }
    return out;
  }
}
