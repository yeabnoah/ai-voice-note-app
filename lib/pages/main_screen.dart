import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hope/pages/about.dart';
import 'package:hope/pages/home.dart';

class EntryApp extends StatefulWidget {
  @override
  State<EntryApp> createState() => _EntryAppState();
}

class _EntryAppState extends State<EntryApp> {
  final List pages = [Home(), About()];

  int indexChange = 0;

  void navigationFunction(int index) {
    setState(() {
      indexChange = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Colors.amberAccent,
            unselectedItemColor: Colors.white,
            backgroundColor: Colors.black,
          ),
        ),
        home: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "NerdNotes",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const Icon(
                  Icons.flutter_dash,
                  size: 30,
                  color: Colors.amberAccent,
                ),
              ],
            ),
            backgroundColor: Colors.black,
          ),
          body: pages[indexChange],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: indexChange,
            onTap: navigationFunction,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "About Me",
              ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: Colors.black,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.amber,
                  ),
                  child: Text(
                    "Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                  title: Text(
                    "Home",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                  title: Text(
                    "Settings",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.help,
                    color: Colors.white,
                  ),
                  title: Text(
                    "Help",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
