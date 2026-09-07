import 'user_model.dart';

class CustomerModel {
  final int id;
  final UserModel? user;
  final String gender;
  final String address;

  CustomerModel({
    required this.id,
    this.user,
    required this.gender,
    required this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : null,
      gender: json['gender'] ?? 'OTHER',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'gender': gender,
      'address': address,
    };
  }
}
