import 'package:flutter/material.dart';
import 'package:time2go/theme/time2go_theme.dart';

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Time2GoTheme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Time2GoTheme.of(context).backgroundColor,
        foregroundColor: Time2GoTheme.of(context).foregroundColor,
        title: const Text('Time2Go'),
      ),
      body: const Center(child: Text('강의실 목록이 여기에 표시됩니다.')),
    );
  }
}
