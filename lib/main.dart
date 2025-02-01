import 'package:flutter/material.dart';
import 'package:hope/screens/home.dart';
import 'package:hope/screens/login.dart';
import 'package:hope/screens/onboarding.dart';
import 'package:hope/screens/register.dart';
import 'package:hope/screens/editor.dart';
import 'package:hope/screens/profile.dart';
import 'package:hope/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await ApiService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/home': (context) => const HomeScreen(),
        '/editor': (context) => const EditorScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
