import 'package:flutter/material.dart';
import '../dashboards/receptionist_dashboard.dart';
import '../customer_vehicle/customer_vehicle_screen.dart';
import '../profile/profile_screen.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF121214)),
            label: 'Front Desk',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF121214)),
            label: 'Customers',
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
