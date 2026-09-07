import 'vehicle_model.dart';
import 'mechanic_model.dart';
import 'booking_model.dart';
import 'spare_part_model.dart';
import 'invoice_model.dart';

class DiagnosisModel {
  final int id;
  final int repairJobId;
  final String finding;
  final String recommendedAction;
  final String? createdAt;

  DiagnosisModel({
    required this.id,
    required this.repairJobId,
    required this.finding,
    required this.recommendedAction,
    this.createdAt,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'] ?? 0,
      repairJobId: json['repair_job'] ?? 0,
      finding: json['finding'] ?? '',
      recommendedAction: json['recommended_action'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class PartUsageModel {
  final int id;
  final int repairJobId;
  final SparePartModel? part;
  final int quantityUsed;
  final double unitPrice;
  final double partsCost;

  PartUsageModel({
    required this.id,
    required this.repairJobId,
    this.part,
    required this.quantityUsed,
    required this.unitPrice,
    required this.partsCost,
  });

  factory PartUsageModel.fromJson(Map<String, dynamic> json) {
    return PartUsageModel(
      id: json['id'] ?? 0,
      repairJobId: json['repair_job'] ?? 0,
      part: json['part'] != null && json['part'] is Map<String, dynamic>
          ? SparePartModel.fromJson(json['part'])
          : null,
      quantityUsed: json['quantity_used'] ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      partsCost: double.tryParse(json['parts_cost']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class RepairJobModel {
  final int id;
  final BookingModel? booking;
  final VehicleModel? vehicle;
  final MechanicModel? mechanic;
  final String checkInDate;
  final int checkInMileage;
  final String fuelLevel;
  final String vehicleCondition;
  final String status;
  final String? startDate;
  final String? expectedCompletionDate;
  final String repairNote;
  final String assignmentStatus;
  final List<DiagnosisModel> diagnoses;
  final List<PartUsageModel> partUsages;
  final InvoiceModel? invoice;

  RepairJobModel({
    required this.id,
    this.booking,
    this.vehicle,
    this.mechanic,
    required this.checkInDate,
    required this.checkInMileage,
    required this.fuelLevel,
    required this.vehicleCondition,
    required this.status,
    this.startDate,
    this.expectedCompletionDate,
    required this.repairNote,
    required this.assignmentStatus,
    this.diagnoses = const [],
    this.partUsages = const [],
    this.invoice,
  });

  factory RepairJobModel.fromJson(Map<String, dynamic> json) {
    return RepairJobModel(
      id: json['id'] ?? 0,
      booking: json['booking'] != null && json['booking'] is Map<String, dynamic>
          ? BookingModel.fromJson(json['booking'])
          : null,
      vehicle: json['vehicle'] != null && json['vehicle'] is Map<String, dynamic>
          ? VehicleModel.fromJson(json['vehicle'])
          : null,
      mechanic: json['mechanic'] != null && json['mechanic'] is Map<String, dynamic>
          ? MechanicModel.fromJson(json['mechanic'])
          : null,
      checkInDate: json['check_in_date'] ?? '',
      checkInMileage: json['check_in_mileage'] ?? 0,
      fuelLevel: json['fuel_level'] ?? 'HALF',
      vehicleCondition: json['vehicle_condition'] ?? '',
      status: json['status'] ?? 'PENDING',
      startDate: json['start_date'],
      expectedCompletionDate: json['expected_completion_date'],
      repairNote: json['repair_note'] ?? '',
      assignmentStatus: json['assignment_status'] ?? 'UNASSIGNED',
      diagnoses: json['diagnoses'] != null && json['diagnoses'] is List
          ? (json['diagnoses'] as List).map((d) => DiagnosisModel.fromJson(d)).toList()
          : [],
      partUsages: json['part_usages'] != null && json['part_usages'] is List
          ? (json['part_usages'] as List).map((p) => PartUsageModel.fromJson(p)).toList()
          : [],
      invoice: json['invoice'] != null && json['invoice'] is Map<String, dynamic>
          ? InvoiceModel.fromJson(json['invoice'])
          : null,
    );
  }
}
