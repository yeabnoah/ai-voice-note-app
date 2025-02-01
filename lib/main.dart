import 'package:flutter/material.dart';
import 'package:hope/screens/login.dart';
import 'package:hope/screens/onboarding.dart';
import 'package:hope/screens/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
      routes: {
        "/": (context) => OnboardingScreen(),
        "/login": (context) => Login(),
        "/register": (context) => Register(),
      },
    );
  }
}
