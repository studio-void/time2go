import 'package:flutter/material.dart';

class ScheduleBlock extends StatelessWidget {
  final String title;
  final TimeOfDay start;
  final TimeOfDay end;
  final Color color;

  const ScheduleBlock({
    super.key,
    required this.title,
    required this.start,
    required this.end,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
