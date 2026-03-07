import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const GasMeterApp());
}

class GasMeterApp extends StatelessWidget {
  const GasMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart Gas Meter",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}