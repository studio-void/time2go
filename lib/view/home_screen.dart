import 'package:flutter/material.dart';
import 'widgets/timetable_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time2Go')),
      body: const Center(child: TimetableWidget()),
    );
  }
}
