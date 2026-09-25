import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';
import '../models/service_model.dart';

class BookingProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<BookingModel> _bookings = [];
  List<VehicleModel> _userVehicles = [];
  List<ServiceModel> _availableServices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get bookings => _bookings;
  List<VehicleModel> get userVehicles => _userVehicles;
  List<ServiceModel> get availableServices => _availableServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.bookings);
      if (response.statusCode == 200) {
        final list = response.data as List;
        _bookings = list.map((json) => BookingModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?.toString() ?? 'Failed to load bookings.';
    } catch (e) {
      _errorMessage = 'An error occurred while loading bookings.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVehiclesAndServices() async {
    try {
      final vRes = await _apiClient.dio.get(ApiConstants.vehicles);
      if (vRes.statusCode == 200) {
        _userVehicles = (vRes.data as List).map((j) => VehicleModel.fromJson(j)).toList();
      }

      final sRes = await _apiClient.dio.get(ApiConstants.services);
      if (sRes.statusCode == 200) {
        _availableServices = (sRes.data as List).map((j) => ServiceModel.fromJson(j)).toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createBooking({
    required int vehicleId,
    required int serviceId,
    required String bookingDate,
    required String bookingTime,
    String problemDescription = '',
    String note = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.bookings,
        data: {
          'vehicle': vehicleId,
          'service': serviceId,
          'booking_date': bookingDate,
          'booking_time': bookingTime,
          'problem_description': problemDescription,
          'note': note,
        },
      );

      if (response.statusCode == 201) {
        await fetchBookings();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?.toString() ?? 'Slot conflict or validation error.';
    } catch (e) {
      _errorMessage = 'Failed to create booking.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> checkInBooking({
    required int bookingId,
    required int checkInMileage,
    required String fuelLevel,
    required String vehicleCondition,
    int? mechanicId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.bookings}$bookingId/check_in/',
        data: {
          'check_in_mileage': checkInMileage,
          'fuel_level': fuelLevel,
          'vehicle_condition': vehicleCondition,
          ...?mechanicId == null ? null : {'mechanic_id': mechanicId},
        },
      );

      if (response.statusCode == 201) {
        await fetchBookings();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to check-in vehicle.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> addVehicle({
    required String plateNumber,
    required String brand,
    required String model,
    required int year,
    required String color,
    required int mileage,
    String? vin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.vehicles,
        data: {
          'plate_number': plateNumber,
          'brand': brand,
          'model': model,
          'year': year,
          'color': color,
          'mileage': mileage,
          if (vin != null && vin.isNotEmpty) 'vin': vin,
        },
      );

      if (response.statusCode == 201) {
        await fetchVehiclesAndServices();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?.toString() ?? 'Failed to add vehicle.';
    } catch (e) {
      _errorMessage = 'An error occurred while adding vehicle.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
