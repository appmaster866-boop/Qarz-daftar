import 'package:flutter/material.dart';

import 'calculator_screen.dart';
import 'daily_sales_screen.dart';

/// Asosiy ekran: pastda navigatsiya paneli bor.
/// Keyinchalik bu yerga "Qarzdorlar" va "Statistika" bo'limlarini qo'shamiz.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _pages = const [
    DailySalesScreen(),
    CalculatorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: tab almashganda ekran holati saqlanib qoladi
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Savdolar',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Kalkulyator',
          ),
        ],
      ),
    );
  }
}
