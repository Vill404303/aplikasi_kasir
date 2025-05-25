import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AplikasiKasirApp());
}

class AplikasiKasirApp extends StatelessWidget {
  const AplikasiKasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kasir',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
