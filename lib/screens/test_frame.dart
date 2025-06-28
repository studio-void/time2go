import 'package:flutter/material.dart';

class TestFrame extends StatelessWidget {
  const TestFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(body: Column(children:[
        Text("Test Frame"),
      ]),)
    );
  }
}