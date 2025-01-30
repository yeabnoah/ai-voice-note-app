import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.amber,
        body: Center(
          child: Container(
            height: 300,
            width: 300,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
