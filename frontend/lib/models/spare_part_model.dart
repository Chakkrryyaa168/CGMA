class SparePartModel {
  final int id;
  final String partNumber;
  final String partName;
  final String category;
  final double unitPrice;
  final int quantity;
  final int minStockQty;
  final String stockStatus;

  SparePartModel({
    required this.id,
    required this.partNumber,
    required this.partName,
    required this.category,
    required this.unitPrice,
    required this.quantity,
    required this.minStockQty,
    required this.stockStatus,
  });

  factory SparePartModel.fromJson(Map<String, dynamic> json) {
    return SparePartModel(
      id: json['id'] ?? 0,
      partNumber: json['part_number'] ?? '',
      partName: json['part_name'] ?? '',
      category: json['category'] ?? '',
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 0,
      minStockQty: json['min_stock_qty'] ?? 5,
      stockStatus: json['stock_status'] ?? 'IN_STOCK',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'part_number': partNumber,
      'part_name': partName,
      'category': category,
      'unit_price': unitPrice,
      'quantity': quantity,
      'min_stock_qty': minStockQty,
      'stock_status': stockStatus,
    };
  }
}
