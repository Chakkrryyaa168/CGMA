class InvoiceModel {
  final int id;
  final int repairJobId;
  final double laborCost;
  final double serviceFee;
  final double partsCost;
  final double discount;
  final double tax;
  final double subtotal;
  final double totalAmount;
  final String? createdAt;

  InvoiceModel({
    required this.id,
    required this.repairJobId,
    required this.laborCost,
    required this.serviceFee,
    required this.partsCost,
    required this.discount,
    required this.tax,
    required this.subtotal,
    required this.totalAmount,
    this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? 0,
      repairJobId: json['repair_job'] ?? 0,
      laborCost: double.tryParse(json['labor_cost']?.toString() ?? '0') ?? 0.0,
      serviceFee: double.tryParse(json['service_fee']?.toString() ?? '0') ?? 0.0,
      partsCost: double.tryParse(json['parts_cost']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repair_job': repairJobId,
      'labor_cost': laborCost,
      'service_fee': serviceFee,
      'parts_cost': partsCost,
      'discount': discount,
      'tax': tax,
      'subtotal': subtotal,
      'total_amount': totalAmount,
    };
  }
}
