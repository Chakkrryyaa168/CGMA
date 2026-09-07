import 'vehicle_model.dart';
import 'service_model.dart';

class BookingModel {
  final int id;
  final VehicleModel? vehicle;
  final int? vehicleId;
  final ServiceModel? service;
  final int? serviceId;
  final String bookingDate;
  final String bookingTime;
  final String problemDescription;
  final String note;
  final String status;
  final String cancelReason;
  final String? createdAt;

  BookingModel({
    required this.id,
    this.vehicle,
    this.vehicleId,
    this.service,
    this.serviceId,
    required this.bookingDate,
    required this.bookingTime,
    required this.problemDescription,
    required this.note,
    required this.status,
    required this.cancelReason,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      vehicle: json['vehicle'] != null && json['vehicle'] is Map<String, dynamic>
          ? VehicleModel.fromJson(json['vehicle'])
          : null,
      vehicleId: json['vehicle'] is int ? json['vehicle'] : null,
      service: json['service'] != null && json['service'] is Map<String, dynamic>
          ? ServiceModel.fromJson(json['service'])
          : null,
      serviceId: json['service'] is int ? json['service'] : null,
      bookingDate: json['booking_date'] ?? '',
      bookingTime: json['booking_time'] ?? '',
      problemDescription: json['problem_description'] ?? '',
      note: json['note'] ?? '',
      status: json['status'] ?? 'PENDING',
      cancelReason: json['cancel_reason'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle': vehicleId ?? vehicle?.id,
      'service': serviceId ?? service?.id,
      'booking_date': bookingDate,
      'booking_time': bookingTime,
      'problem_description': problemDescription,
      'note': note,
      'status': status,
      'cancel_reason': cancelReason,
    };
  }
}
