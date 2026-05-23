import 'package:flutter/material.dart';

void main() {
  runApp(const PartnerWebApp());
}

class PartnerWebApp extends StatelessWidget {
  const PartnerWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyTrunk Partner',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Partner Web Scaffold Ready'),
        ),
      ),
    );
  }
}
