import 'package:flutter/material.dart';

void main() {
  runApp(const CashierWebApp());
}

class CashierWebApp extends StatelessWidget {
  const CashierWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiggyTrunk Cashier',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Cashier Web Scaffold Ready'),
        ),
      ),
    );
  }
}
