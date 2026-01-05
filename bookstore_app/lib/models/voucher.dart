class Voucher {
  const Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.startAt,
    required this.endAt,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  final int id;
  final String code;
  final String title;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minOrderValue;
  final DateTime? startAt;
  final DateTime? endAt;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as int? ?? 0,
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discountType']?.toString() ?? '',
      discountValue: _parseDouble(json['discountValue']),
      maxDiscount: _parseNullableDouble(json['maxDiscount']),
      minOrderValue: _parseDouble(json['minOrderValue']),
      startAt: _parseDate(json['startAt']),
      endAt: _parseDate(json['endAt']),
      usageLimit: _parseNullableInt(json['usageLimit']),
      usedCount: _parseInt(json['usedCount']),
      isActive: json['isActive'] == true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    return _parseDouble(value);
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
