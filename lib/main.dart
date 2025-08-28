import 'package:flutter/material.dart';
import 'package:time2go/firebase_options.dart';
import 'package:time2go/view/home_screen.dart';
import 'package:time2go/view/meet_screen.dart';
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
      title: 'Time2Go',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Time2GoTheme.light.foregroundColor,
          displayColor: Time2GoTheme.light.foregroundColor,
        ),
        extensions: [Time2GoTheme.light],
      ),
      darkTheme: ThemeData(
        fontFamily: 'Pretendard',
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Time2GoTheme.dark.foregroundColor,
          displayColor: Time2GoTheme.dark.foregroundColor,
        ),
        extensions: [Time2GoTheme.dark],
      ),
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/timetable': (context) => const TimetableScreen(),
        '/meet': (context) => const MeetScreen(),
      },
    );
  }
}
