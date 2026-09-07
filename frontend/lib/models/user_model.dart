class UserModel {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String phone;
  final String? profilePhoto;
  final String accountStatus;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.phone,
    this.profilePhoto,
    required this.accountStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      phone: json['phone'] ?? '',
      profilePhoto: json['profile_photo'],
      accountStatus: json['account_status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'profile_photo': profilePhoto,
      'account_status': accountStatus,
    };
  }
}
