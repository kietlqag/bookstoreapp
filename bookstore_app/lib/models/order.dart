class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.recipientName,
    required this.phoneNumber,
    required this.shippingAddressNew,
    required this.shippingAddressOld,
    required this.subtotal,
    required this.shippingFee,
    required this.productDiscount,
    required this.shippingDiscount,
    required this.orderDate,
    required this.items,
  });

  final int id;
  final String status;
  final double totalPrice;
  final String recipientName;
  final String phoneNumber;
  final String shippingAddressNew;
  final String shippingAddressOld;
  final double subtotal;
  final double shippingFee;
  final double productDiscount;
  final double shippingDiscount;
  final DateTime? orderDate;
  final List<OrderItemSummary> items;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int? ?? 0,
      status: json['status']?.toString() ?? '',
      totalPrice: _parseDouble(json['totalPrice']),
      recipientName: json['recipientName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      shippingAddressNew: json['shippingAddressNew']?.toString() ?? '',
      shippingAddressOld: json['shippingAddressOld']?.toString() ?? '',
      subtotal: _parseDouble(json['subtotal']),
      shippingFee: _parseDouble(json['shippingFee']),
      productDiscount: _parseDouble(json['productDiscount']),
      shippingDiscount: _parseDouble(json['shippingDiscount']),
      orderDate: _parseDate(json['orderDate']),
      items: (json['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItemSummary.fromJson)
          .toList(),
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

class OrderItemSummary {
  const OrderItemSummary({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.quantity,
    required this.price,
    required this.bookImageUrl,
    required this.bookPrice,
    required this.bookDiscount,
  });

  final int id;
  final int bookId;
  final String bookTitle;
  final int quantity;
  final double price;
  final String bookImageUrl;
  final double bookPrice;
  final double bookDiscount;

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      bookTitle: json['bookTitle']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 0,
      price: _parseDouble(json['price']),
      bookImageUrl: json['bookImageUrl']?.toString() ?? '',
      bookPrice: _parseDouble(json['bookPrice']),
      bookDiscount: _parseDouble(json['bookDiscount']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
