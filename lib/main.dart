import 'package:flutter/material.dart';
import 'pages/start_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intercity Parcel Delivery',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: StartScreen(),
    );
  }
}
//