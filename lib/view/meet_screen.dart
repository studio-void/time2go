import 'package:flutter/material.dart';
import 'package:time2go/theme/time2go_theme.dart';

class MeetScreen extends StatelessWidget {
  const MeetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meetId = ModalRoute.of(context)!.settings.arguments as String?;

    return Scaffold(
      backgroundColor: Time2GoTheme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Time2GoTheme.of(context).backgroundColor,
        foregroundColor: Time2GoTheme.of(context).foregroundColor,
        title: Text(meetId ?? '강의실'),
        centerTitle: false,
      ),
      body: const Center(child: Text('강의실 목록이 여기에 표시됩니다.')),
    );
  }
}
