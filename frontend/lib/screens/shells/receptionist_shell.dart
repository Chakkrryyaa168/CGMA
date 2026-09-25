import 'package:flutter/material.dart';
import '../dashboards/receptionist_dashboard.dart';
import '../customer_vehicle/customer_vehicle_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/cool_circular_nav_bar.dart';

class ReceptionistShell extends StatefulWidget {
  const ReceptionistShell({super.key});

  @override
  State<ReceptionistShell> createState() => _ReceptionistShellState();
}

class _ReceptionistShellState extends State<ReceptionistShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ReceptionistDashboard(),
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
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Desk',
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
