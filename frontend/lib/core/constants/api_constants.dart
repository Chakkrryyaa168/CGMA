import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable base URL: Android emulator uses 10.0.2.2, iOS/Web/Desktop uses localhost
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/';
    return 'http://localhost:8000/api/';
  }

  static const String login = 'auth/login/';
  static const String refresh = 'auth/refresh/';
  static const String register = 'auth/register/';
  static const String me = 'auth/me/';

  static const String users = 'users/';
  static const String customers = 'customers/';
  static const String mechanics = 'mechanics/';
  static const String vehicles = 'vehicles/';
  static const String categories = 'categories/';
  static const String services = 'services/';
  static const String bookings = 'bookings/';
  static const String repairJobs = 'repair-jobs/';
  static const String diagnoses = 'diagnoses/';
  static const String spareParts = 'spare-parts/';
  static const String partUsages = 'part-usages/';
  static const String estimates = 'estimates/';
  static const String invoices = 'invoices/';
  static const String payments = 'payments/';
  static const String serviceHistory = 'service-history/';
  static const String reminders = 'reminders/';
  static const String notifications = 'notifications/';
}
