import 'package:flutter/material.dart';
import 'package:time2go/firebase_options.dart';
import 'package:time2go/view/timetable_screen.dart';
import 'package:time2go/theme/time2go_theme.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const TimetableScreen(),
    );
  }
}
