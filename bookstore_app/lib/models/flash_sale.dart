import 'book.dart';

class FlashSale {
  const FlashSale({
    required this.id,
    required this.name,
    required this.startAt,
    required this.endAt,
    required this.discountPercent,
    required this.books,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final DateTime startAt;
  final DateTime endAt;
  final double discountPercent;
  final List<Book> books;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FlashSale.fromJson(Map<String, dynamic> json) {
    final booksJson = json['books'] as List<dynamic>? ?? [];
    final books = booksJson.map((bookJson) => Book.fromJson(bookJson)).toList();

    return FlashSale(
      id: json['id'] as int,
      name: json['name'] as String,
      startAt: DateTime.parse(json['startAt'] as String).toLocal(),
      endAt: DateTime.parse(json['endAt'] as String).toLocal(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      books: books,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toLocal()
          : null,
    );
  }

  bool get isActive {
    final now = DateTime.now();
    // Flash sale is active if current time is between startAt and endAt (inclusive)
    return (now.isAtSameMomentAs(startAt) || now.isAfter(startAt)) && 
           (now.isBefore(endAt) || now.isAtSameMomentAs(endAt));
  }

  Duration? get timeRemaining {
    final now = DateTime.now();
    // If flash sale hasn't started yet
    if (now.isBefore(startAt)) {
      return null; // Not active yet
    }
    // If flash sale has ended
    if (now.isAfter(endAt)) {
      return null; // Already ended
    }
    // Calculate remaining time until endAt
    return endAt.difference(now);
  }
}
