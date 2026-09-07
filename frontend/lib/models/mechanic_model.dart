import 'user_model.dart';

class MechanicModel {
  final int id;
  final UserModel? user;
  final String skill;
  final String specialization;
  final String availabilityStatus;

  MechanicModel({
    required this.id,
    this.user,
    required this.skill,
    required this.specialization,
    required this.availabilityStatus,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) {
    return MechanicModel(
      id: json['id'] ?? 0,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : null,
      skill: json['skill'] ?? '',
      specialization: json['specialization'] ?? '',
      availabilityStatus: json['availability_status'] ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'skill': skill,
      'specialization': specialization,
      'availability_status': availabilityStatus,
    };
  }

  String get displayName => user?.fullName ?? 'Mechanic #$id';
}
