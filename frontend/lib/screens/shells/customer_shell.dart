import 'package:flutter/material.dart';
import '../dashboards/customer_dashboard.dart';
import '../booking/create_booking_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/cool_circular_nav_bar.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CustomerDashboard(),
    CreateBookingScreen(),
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
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car,
            label: 'Garage',
          ),
          AnimatedNavItem(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: 'Book',
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
