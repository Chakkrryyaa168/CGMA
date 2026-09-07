import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String get userRole => _currentUser?.role ?? 'GUEST';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        await _storageService.saveTokens(access: access, refresh: refresh);
        _currentUser = UserModel.fromJson(userData);
        await _storageService.saveUserData(
          role: _currentUser!.role,
          id: _currentUser!.id,
          email: _currentUser!.email,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['detail'] ?? 'Invalid email or password.';
    } catch (e) {
      _errorMessage = 'An error occurred during login.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String phone = '',
    String gender = 'OTHER',
    String address = '',
    String skill = '',
    String specialization = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role,
          'phone': phone,
          'gender': gender,
          'address': address,
          'skill': skill,
          'specialization': specialization,
        },
      );

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data.toString() ?? 'Registration failed.';
    } catch (e) {
      _errorMessage = 'An error occurred during registration.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> checkAutoLogin() async {
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await _apiClient.dio.get(ApiConstants.me);
        if (response.statusCode == 200) {
          _currentUser = UserModel.fromJson(response.data);
          notifyListeners();
        }
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> logout() async {
    await _storageService.clear();
    _currentUser = null;
    notifyListeners();
  }
}
