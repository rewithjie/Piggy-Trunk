import 'package:flutter/material.dart';

void main() {
  runApp(const HogRaiserMobileApp());
}

class HogRaiserMobileApp extends StatelessWidget {
  const HogRaiserMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyTrunk Hog Raiser',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Hog Raiser Mobile Scaffold Ready'),
        ),
      ),
    );
  }
}
