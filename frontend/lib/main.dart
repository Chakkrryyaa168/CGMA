import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/repair_job_provider.dart';
import 'providers/inventory_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shells/admin_shell.dart';
import 'screens/shells/receptionist_shell.dart';
import 'screens/shells/mechanic_shell.dart';
import 'screens/shells/customer_shell.dart';
import 'screens/main_navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GarageApp());
}

class GarageApp extends StatelessWidget {
  const GarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAutoLogin()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => RepairJobProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'Car Garage Management System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.oswaldTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFC700),
            primary: const Color(0xFFFFC700),
            onPrimary: const Color(0xFF121214),
            secondary: const Color(0xFF18181B),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: const Color(0xFF121214),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF18181B),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC700),
              foregroundColor: const Color(0xFF121214),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFFFC700),
            secondarySelectedColor: const Color(0xFFFFC700),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF18181B),
            indicatorColor: const Color(0xFFFFC700),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF121214));
              }
              return const IconThemeData(color: Colors.white70);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(color: Color(0xFFFFC700), fontWeight: FontWeight.bold, fontSize: 12);
              }
              return const TextStyle(color: Colors.white70, fontSize: 12);
            }),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class AppLandingGate extends StatelessWidget {
  const AppLandingGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        switch (auth.userRole.toUpperCase()) {
          case 'ADMIN':
            return const AdminShell();
          case 'RECEPTIONIST':
            return const ReceptionistShell();
          case 'MECHANIC':
            return const MechanicShell();
          case 'CUSTOMER':
            return const CustomerShell();
          default:
            return const MainNavigationShell();
        }
      },
    );
  }
}
