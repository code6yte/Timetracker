import 'package:flutter/material.dart';
import 'tasks_tab.dart';
import 'timer_tab.dart';
import 'statistics_tab.dart';
import 'settings_screen.dart';
import '../widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const TasksTab(),
    const TimerTab(),
    const StatisticsTab(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      // AppBar removed as requested
      body: _tabs[_currentIndex],
      bottomNavigationBar: GlassContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        borderRadius: BorderRadius.circular(24),
        color: Colors.black,
        opacity: 0.3,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
