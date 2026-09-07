import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/spare_part_model.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<SparePartModel> _spareParts = [];
  List<SparePartModel> _lowStockParts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SparePartModel> get spareParts => _spareParts;
  List<SparePartModel> get lowStockParts => _lowStockParts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSpareParts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.spareParts);
      if (response.statusCode == 200) {
        final list = response.data as List;
        _spareParts = list.map((json) => SparePartModel.fromJson(json)).toList();
      }

      final lowRes = await _apiClient.dio.get('${ApiConstants.spareParts}low_stock/');
      if (lowRes.statusCode == 200) {
        final lowList = lowRes.data as List;
        _lowStockParts = lowList.map((json) => SparePartModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?.toString() ?? 'Failed to load inventory.';
    } catch (e) {
      _errorMessage = 'An error occurred loading inventory.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSparePart({
    required String partNumber,
    required String partName,
    required String category,
    required double unitPrice,
    required int quantity,
    required int minStockQty,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.spareParts,
        data: {
          'part_number': partNumber,
          'part_name': partName,
          'category': category,
          'unit_price': unitPrice,
          'quantity': quantity,
          'min_stock_qty': minStockQty,
        },
      );

      if (response.statusCode == 201) {
        await fetchSpareParts();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to add spare part.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
