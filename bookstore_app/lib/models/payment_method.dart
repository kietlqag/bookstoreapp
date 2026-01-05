class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.code,
    required this.title,
    required this.provider,
    required this.methodType,
    required this.sortOrder,
    required this.isActive,
  });

  final int id;
  final String code;
  final String title;
  final String provider;
  final String methodType;
  final int sortOrder;
  final bool isActive;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int? ?? 0,
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      methodType: json['methodType']?.toString() ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] == true,
    );
  }
}
