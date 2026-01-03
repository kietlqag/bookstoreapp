import 'book.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.book,
    required this.quantity,
  });

  final int id;
  final Book book;
  final int quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CartItem(
      id: parseInt(json['id']),
      book: Book.fromJson(json['book'] as Map<String, dynamic>? ?? const {}),
      quantity: parseInt(json['quantity']),
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      book: book,
      quantity: quantity ?? this.quantity,
    );
  }
}

