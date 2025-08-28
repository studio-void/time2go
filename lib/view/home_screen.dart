import 'package:flutter/material.dart';
import 'package:time2go/theme/time2go_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Time2GoTheme.of(context).cardBorderColor,
                  width: 1,
                ),
              ),
              color: Time2GoTheme.of(context).backgroundColor,
              elevation: 0,
              child: ListTile(
                leading: Icon(Icons.calendar_month, size: 32),
                title: Text(
                  '시간표',
                  style: TextStyle(
                    color: Time2GoTheme.of(context).foregroundColor,
                  ),
                ),
                subtitle: Text(
                  '나의 시간표를 확인하고 관리합니다',
                  style: TextStyle(
                    color: Time2GoTheme.of(
                      context,
                    ).foregroundColor.withAlpha(150),
                  ),
                ),
                iconColor: Time2GoTheme.of(context).foregroundColor,
                onTap: () {
                  Navigator.of(context).pushNamed('/timetable');
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Time2GoTheme.of(context).cardBorderColor,
                  width: 1,
                ),
              ),
              color: Time2GoTheme.of(context).backgroundColor,
              elevation: 0,
              child: ListTile(
                leading: Icon(Icons.meeting_room, size: 32),
                title: Text(
                  '강의실 목록',
                  style: TextStyle(
                    color: Time2GoTheme.of(context).foregroundColor,
                  ),
                ),
                subtitle: Text(
                  '강의실 현황을 확인합니다',
                  style: TextStyle(
                    color: Time2GoTheme.of(
                      context,
                    ).foregroundColor.withAlpha(150),
                  ),
                ),
                iconColor: Time2GoTheme.of(context).foregroundColor,
                onTap: () {
                  Navigator.of(context).pushNamed('/room_list');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
