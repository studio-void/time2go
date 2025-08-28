import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:time2go/view/widgets/calendar_grid.dart';
import 'package:time2go/viewmodel/meet_viewmodel.dart';

class MeetScreen extends StatelessWidget {
  const MeetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? meetId;
    Color? myColor;
    if (args is Map) {
      meetId = args['meetId'] as String?;
      myColor = args['color'] as Color?;
    } else if (args is String) {
      meetId = args;
    }

    final time2goTheme = Time2GoTheme.of(context);

    if (meetId == null || myColor == null) {
      debugPrint('meetId=$meetId, myColor=$myColor');

      return Scaffold(
        backgroundColor: time2goTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: time2goTheme.backgroundColor,
          foregroundColor: time2goTheme.foregroundColor,
          title: const Text('미트 정보 없음'),
        ),
        body: const Center(child: Text('미트 정보가 올바르지 않습니다.')),
      );
    }

    return ChangeNotifierProvider<MeetViewModel>(
      create: (ctx) {
        final vm = MeetViewModel(meetId: meetId!, myColor: myColor!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.loadMembersAndSchedules();
        });
        return vm;
      },
      child: Consumer<MeetViewModel>(
        builder: (context, vm, _) {
          final time2goTheme = Time2GoTheme.of(context);
          final blockColors = time2goTheme.blockColors;
          final gridColor = time2goTheme.gridColor;
          vm.showSnack ??= (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                duration: const Duration(seconds: 1),
              ),
            );
          };

          return Scaffold(
            backgroundColor: time2goTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: time2goTheme.backgroundColor,
              foregroundColor: time2goTheme.foregroundColor,
              title: Text(meetId ?? '빈 미트'),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.people),
                  tooltip: '멤버 보기',
                  onPressed: () {
                    _showMembersSheet(context, vm);
                  },
                ),
              ],
            ),
            body:
                vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CalendarGrid(
                      schedules: vm.mergedSchedules,
                      blockColors: blockColors,
                      gridColor: gridColor,
                    ),
          );
        },
      ),
    );
  }
}

void _showMembersSheet(BuildContext context, MeetViewModel vm) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Time2GoTheme.of(context).backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final members = vm.members;
      if (members.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('아직 멤버가 없습니다.')),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '미트 멤버',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = members[index];
                  // Assuming member has `name` and `color` fields. Adjust if different.
                  final String name = m.displayName;
                  final Color color = m.color;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        color: Time2GoTheme.of(context).foregroundColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
