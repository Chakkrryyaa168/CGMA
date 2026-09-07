import 'customer_model.dart';

class VehicleModel {
  final int id;
  final CustomerModel? customer;
  final int? customerId;
  final String plateNumber;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String? vin;
  final String? engineNumber;
  final int mileage;
  final String? vehiclePhoto;
  final String status;

  VehicleModel({
    required this.id,
    this.customer,
    this.customerId,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    this.vin,
    this.engineNumber,
    required this.mileage,
    this.vehiclePhoto,
    required this.status,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic>
          ? CustomerModel.fromJson(json['customer'])
          : null,
      customerId: json['customer'] is int ? json['customer'] : null,
      plateNumber: json['plate_number'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 2024,
      color: json['color'] ?? '',
      vin: json['vin'],
      engineNumber: json['engine_number'],
      mileage: json['mileage'] ?? 0,
      vehiclePhoto: json['vehicle_photo'],
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customerId ?? customer?.id,
      'plate_number': plateNumber,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'vin': vin,
      'engine_number': engineNumber,
      'mileage': mileage,
      'vehicle_photo': vehiclePhoto,
      'status': status,
    };
  }

  String get displayName => '$brand $model ($plateNumber)';
}
