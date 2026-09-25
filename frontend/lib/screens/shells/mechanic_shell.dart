import 'package:flutter/material.dart';
import '../dashboards/mechanic_dashboard.dart';
import '../profile/profile_screen.dart';
import '../../widgets/cool_circular_nav_bar.dart';

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
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CoolCircularNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        items: const [
          AnimatedNavItem(
            icon: Icons.build_circle_outlined,
            selectedIcon: Icons.build_circle,
            label: 'Workbench',
          ),
          AnimatedNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
