import 'package:flutter/material.dart';
import 'package:smart_gas_meter_app/screens/splash_screen.dart';
import 'package:smart_gas_meter_app/theme/app_theme.dart';

void main() {
  runApp(const SmartGasMeterApp());
}

class SmartGasMeterApp extends StatelessWidget {
  const SmartGasMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IndexOne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}