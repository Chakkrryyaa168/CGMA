import 'package:flutter/material.dart';
import '../dashboards/admin_dashboard.dart';
import '../customer_vehicle/customer_vehicle_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/cool_circular_nav_bar.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboard(),
    CustomerVehicleScreen(),
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
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings,
            label: 'Admin',
          ),
          AnimatedNavItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Clients',
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
