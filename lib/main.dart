import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hope/screens/home.dart';
import 'package:hope/screens/login.dart';
import 'package:hope/screens/onboarding.dart';
import 'package:hope/screens/register.dart';
import 'package:hope/screens/editor.dart';
import 'package:hope/screens/profile.dart';
import 'package:hope/screens/note_reader.dart';
import 'package:hope/services/api_service.dart';
import 'package:hope/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = await ApiService.isLoggedIn();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService(prefs)),
        Provider(create: (_) => ApiService()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Voice Notes',
          theme: themeService.currentTheme,
          initialRoute: isLoggedIn ? '/home' : '/',
          routes: {
            '/': (context) => const OnboardingScreen(),
            '/login': (context) => const Login(),
            '/register': (context) => const Register(),
            '/home': (context) => const HomeScreen(),
            '/editor': (context) => const EditorScreen(),
            '/reader': (context) => const NoteReaderScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
