class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.orderDate,
  });

  final int id;
  final String status;
  final double totalPrice;
  final DateTime? orderDate;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int? ?? 0,
      status: json['status']?.toString() ?? '',
      totalPrice: _parseDouble(json['totalPrice']),
      orderDate: _parseDate(json['orderDate']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
