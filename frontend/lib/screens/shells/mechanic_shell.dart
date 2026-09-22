import 'package:flutter/material.dart';
import '../dashboards/mechanic_dashboard.dart';
import '../profile/profile_screen.dart';

class MechanicShell extends StatefulWidget {
  const MechanicShell({super.key});

  @override
  State<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends State<MechanicShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MechanicDashboard(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle, color: Color(0xFF121214)),
            label: 'Workbench',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF121214)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
