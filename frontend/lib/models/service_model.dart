class ServiceCategoryModel {
  final int id;
  final String name;

  ServiceCategoryModel({required this.id, required this.name});

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class ServiceModel {
  final int id;
  final ServiceCategoryModel? category;
  final String name;
  final String description;
  final double standardPrice;
  final int estimatedDurationMin;
  final String status;

  ServiceModel({
    required this.id,
    this.category,
    required this.name,
    required this.description,
    required this.standardPrice,
    required this.estimatedDurationMin,
    required this.status,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      category: json['category'] != null && json['category'] is Map<String, dynamic>
          ? ServiceCategoryModel.fromJson(json['category'])
          : null,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      standardPrice: double.tryParse(json['standard_price']?.toString() ?? '0') ?? 0.0,
      estimatedDurationMin: json['estimated_duration_min'] ?? 60,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'standard_price': standardPrice,
      'estimated_duration_min': estimatedDurationMin,
      'status': status,
    };
  }
}
