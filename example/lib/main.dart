import 'package:flutter/material.dart';

import 'asleep_page.dart';
import 'in_bed_page.dart';
import 'normal_page.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titles = ['Normal', 'Asleep', 'In Bed'];
  static const _pages = [NormalPage(), AsleepPage(), InBedPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('flutter_sleep_chart — ${_titles[_index]}')),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bedtime_outlined),
            label: 'Normal',
          ),
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            label: 'Asleep',
          ),
          NavigationDestination(
            icon: Icon(Icons.hotel_outlined),
            label: 'In Bed',
          ),
        ],
      ),
    );
  }
}
