import 'package:flutter/material.dart';
import 'package:time2go/model/firebase_store_helper.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:time2go/view/widgets/navigation_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MeetStore store = MeetStore(FirebaseFirestore.instance);

    return Scaffold(
      backgroundColor: Time2GoTheme.of(context).backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Time2Go",
              style: TextStyle(
                fontSize: 50,
                fontVariations: [const FontVariation('wght', 800)],
                fontFamily: 'Pretendard',
                color: Time2GoTheme.of(context).foregroundColor,
              ),
            ),
            const SizedBox(height: 24),
            NavigationCard(
              icon: Icons.calendar_month_rounded,
              title: '시간표',
              subtitle: '나의 시간표를 확인하고 관리합니다',
              onTap: () => Navigator.of(context).pushNamed('/timetable'),
            ),
            const SizedBox(height: 12),
            NavigationCard(
              icon: Icons.meeting_room_rounded,
              title: '미트 찾기 혹은 생성',
              subtitle: '미트를 찾아 입장하거나 새로 만듭니다',
              onTap: () async {
                final idController = TextEditingController();
                DateTime rangeStartLocal = DateTime.now();
                final theme = Time2GoTheme.of(context);

                // 1) First dialog: Ask only ID + start date
                final idResult = await showDialog<
                  ({String id, DateTime rangeStart})
                >(
                  context: context,
                  builder: (ctx) {
                    return StatefulBuilder(
                      builder: (ctx, setState) {
                        return AlertDialog(
                          backgroundColor: theme.backgroundColor,
                          title: const Text('미트 입장'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('미트 ID (필수)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: idController,
                                decoration: const InputDecoration(
                                  hintText: '예) cs-study-0901',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('시작 날짜 (7일간 범위로 계산)'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${rangeStartLocal.year}-${rangeStartLocal.month.toString().padLeft(2, '0')}-${rangeStartLocal.day.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: ctx,
                                        initialDate: rangeStartLocal,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setState(
                                          () => rangeStartLocal = picked,
                                        );
                                      }
                                    },
                                    child: const Text('날짜 선택'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                final id = idController.text.trim();
                                if (id.isEmpty) {
                                  Navigator.of(ctx).pop(null);
                                  return;
                                }
                                Navigator.of(
                                  ctx,
                                ).pop((id: id, rangeStart: rangeStartLocal));
                              },
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (idResult == null) return;

                final meetId = idResult.id;
                final rangeStartUtc =
                    DateTime(
                      idResult.rangeStart.year,
                      idResult.rangeStart.month,
                      idResult.rangeStart.day,
                    ).toUtc();

                // 2) Check Firestore for existing room
                final db = FirebaseFirestore.instance;
                final roomRef = db.collection('rooms').doc(meetId);
                final snap = await roomRef.get();

                if (snap.exists) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('기존 미트를 불러옵니다.')),
                  );
                  Navigator.of(context).pushNamed('/meet', arguments: meetId);
                  return;
                }

                // 3) If not exists, ask for Title and create
                final titleController = TextEditingController(text: 'Title');
                if (!context.mounted) return;
                final title = await showDialog<String>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        backgroundColor: theme.backgroundColor,
                        title: const Text('새 미트 생성'),
                        content: TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: '제목',
                            hintText: '예) 스터디 미트',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.of(ctx).pop(
                                  titleController.text.trim().isEmpty
                                      ? 'Title'
                                      : titleController.text.trim(),
                                ),
                            child: const Text('생성'),
                          ),
                        ],
                      ),
                );

                if (title == null) return; // canceled

                await roomRef.set({
                  'title': title,
                  'rangeStart': Timestamp.fromDate(rangeStartUtc),
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('새 미트를 생성했어요.')));
                Navigator.of(context).pushNamed('/meet', arguments: meetId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
