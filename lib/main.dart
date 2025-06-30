import 'package:flutter/material.dart';
import 'package:time2go/screens/home_screen.dart';
import 'package:time2go/screens/test_frame.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const Time2GoApp());
}

class Time2GoApp extends StatelessWidget {
  const Time2GoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TestFrame(),
    );
  }
}
