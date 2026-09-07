import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/repair_job_model.dart';
import '../models/mechanic_model.dart';

class RepairJobProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<RepairJobModel> _repairJobs = [];
  List<MechanicModel> _mechanics = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RepairJobModel> get repairJobs => _repairJobs;
  List<MechanicModel> get mechanics => _mechanics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRepairJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.repairJobs);
      if (response.statusCode == 200) {
        final list = response.data as List;
        _repairJobs = list.map((json) => RepairJobModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?.toString() ?? 'Failed to load repair jobs.';
    } catch (e) {
      _errorMessage = 'An error occurred loading repair jobs.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMechanics() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.mechanics);
      if (response.statusCode == 200) {
        _mechanics = (response.data as List).map((j) => MechanicModel.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> assignMechanic(int repairJobId, int mechanicId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.repairJobs}$repairJobId/assign_mechanic/',
        data: {'mechanic_id': mechanicId},
      );
      if (response.statusCode == 200) {
        await fetchRepairJobs();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to assign mechanic.';
    }
    return false;
  }

  Future<bool> addDiagnosis(int repairJobId, String finding, String recommendedAction) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.diagnoses,
        data: {
          'repair_job': repairJobId,
          'finding': finding,
          'recommended_action': recommendedAction,
        },
      );
      if (response.statusCode == 201) {
        await fetchRepairJobs();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to record diagnosis.';
    }
    return false;
  }

  Future<bool> addPartUsage(int repairJobId, int partId, int quantityUsed) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.partUsages,
        data: {
          'repair_job': repairJobId,
          'part': partId,
          'quantity_used': quantityUsed,
        },
      );
      if (response.statusCode == 201) {
        await fetchRepairJobs();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?.toString() ?? 'Insufficient stock or invalid part.';
    } catch (e) {
      _errorMessage = 'Failed to add part usage.';
    }
    return false;
  }

  Future<bool> completeJob(int repairJobId) async {
    try {
      final response = await _apiClient.dio.post('${ApiConstants.repairJobs}$repairJobId/complete_job/');
      if (response.statusCode == 200) {
        await fetchRepairJobs();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to complete repair job.';
    }
    return false;
  }

  Future<bool> generateInvoice(int repairJobId, {double laborCost = 50.0}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.invoices}generate_from_job/',
        data: {'repair_job_id': repairJobId, 'labor_cost': laborCost},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRepairJobs();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to generate invoice.';
    }
    return false;
  }
}
