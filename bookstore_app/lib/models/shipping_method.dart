class ShippingMethod {
  const ShippingMethod({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.fee,
    required this.minDays,
    required this.maxDays,
    required this.sortOrder,
  });

  final int id;
  final String code;
  final String title;
  final String? subtitle;
  final String? description;
  final double fee;
  final int minDays;
  final int maxDays;
  final int sortOrder;

  factory ShippingMethod.fromJson(Map<String, dynamic> json) {
    return ShippingMethod(
      id: json['id'] as int? ?? 0,
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      fee: _parseDouble(json['fee']),
      minDays: _parseInt(json['minDays']),
      maxDays: _parseInt(json['maxDays']),
      sortOrder: _parseInt(json['sortOrder']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
