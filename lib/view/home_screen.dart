import 'package:flutter/material.dart';
import 'package:time2go/model/firebase_store_helper.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:time2go/view/widgets/navigation_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Convert a Color to a "#RRGGBB" hex string (drop alpha)
  String _toHex(Color c) {
    final v = c.value & 0xFFFFFF;
    return '#'
        '${((v >> 16) & 0xFF).toRadixString(16).padLeft(2, '0')}'
        '${((v >> 8) & 0xFF).toRadixString(16).padLeft(2, '0')}'
        '${(v & 0xFF).toRadixString(16).padLeft(2, '0')}';
  }

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
                        String formatDate(DateTime d) =>
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

                              const SizedBox(height: 24),

                              const Text('시작 날짜 (7일간 범위로 계산)'),

                              const SizedBox(height: 6),

                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: rangeStartLocal,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    builder: (pickerCtx, child) {
                                      final base = Theme.of(pickerCtx);

                                      return Theme(
                                        data: base.copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: theme.foregroundColor,
                                            onPrimary: theme.backgroundColor,
                                            surface: theme.backgroundColor,
                                            onSurface: theme.foregroundColor,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.foregroundColor,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => rangeStartLocal = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          Time2GoTheme.of(context).borderColor,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        color:
                                            Time2GoTheme.of(
                                              context,
                                            ).foregroundColor,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          formatDate(rangeStartLocal),
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.expand_more_rounded),
                                    ],
                                  ),
                                ),
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

                // 2) Check if room exists via helper
                final existing = await store.getRoomOnce(meetId);

                // 2-1) Ask for display name (and title if creating)
                final displayNameController = TextEditingController(text: '익명');
                final titleController = TextEditingController(text: 'Title');
                final blockColors = Time2GoTheme.light.blockColors;
                int selectedColorIdx = 0;

                if (!context.mounted) return;
                final result = await showDialog<
                  ({String displayName, String? title, Color color})
                >(
                  context: context,
                  builder: (ctx) {
                    return StatefulBuilder(
                      builder: (ctx, setState) {
                        return AlertDialog(
                          backgroundColor: theme.backgroundColor,
                          title: Text(
                            existing == null ? '입장 정보 입력' : '표시 이름 입력',
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('표시 이름'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: displayNameController,
                                decoration: const InputDecoration(
                                  hintText: '예) 민수',
                                ),
                              ),
                              if (existing == null) ...[
                                const SizedBox(height: 16),
                                const Text('제목 (새 미트 생성 시)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    hintText: '예) 스터디 미트',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              const Text('표시 색상 선택'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: List.generate(blockColors.length, (
                                  i,
                                ) {
                                  return GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => selectedColorIdx = i,
                                        ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: blockColors[i],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              selectedColorIdx == i
                                                  ? Colors.black
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
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
                                final name =
                                    displayNameController.text.trim().isEmpty
                                        ? '익명'
                                        : displayNameController.text.trim();
                                final title =
                                    existing == null
                                        ? (titleController.text.trim().isEmpty
                                            ? 'Title'
                                            : titleController.text.trim())
                                        : null;
                                final color = blockColors[selectedColorIdx];
                                Navigator.of(ctx).pop((
                                  displayName: name,
                                  title: title,
                                  color: color,
                                ));
                              },
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (result == null) return;

                // 3) Ensure room and join via helper (require authenticated user)
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('로그인이 필요해요. 구글 로그인 후 다시 시도해 주세요.'),
                    ),
                  );
                  return;
                }
                final uid = user.uid;
                if (existing == null) {
                  final outcome = await store.ensureRoomAndJoin(
                    roomId: meetId,
                    title: result.title!,
                    rangeStartUtc: rangeStartUtc,
                    uid: uid,
                    displayName: result.displayName,
                    colorHex: _toHex(result.color),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        outcome.created ? '새 미트를 생성하고 입장했어요.' : '기존 미트에 입장했어요.',
                      ),
                    ),
                  );
                } else {
                  await store.joinRoom(
                    roomId: meetId,
                    uid: uid,
                    displayName: result.displayName,
                    colorHex: _toHex(result.color),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('기존 미트에 입장했어요.')),
                  );
                }

                // 4) Navigate to meet screen
                if (!context.mounted) return;
                Navigator.of(context).pushNamed(
                  '/meet',
                  arguments: {'meetId': meetId, 'color': result.color},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
