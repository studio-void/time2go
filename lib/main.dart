import 'package:flutter/material.dart';
import 'package:time2go/view/home_screen.dart';
import 'package:time2go/theme/time2go_theme.dart';

void main() {
  runApp(const Time2GoApp());
}

class Time2GoApp extends StatelessWidget {
  const Time2GoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        extensions: [Time2GoTheme.light],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        extensions: [Time2GoTheme.dark],
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
