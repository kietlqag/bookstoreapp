class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.rating,
    required this.cover,
    required this.category,
    required this.description,
    this.stockQuantity = 0,
    this.soldQuantity = 0,
    this.discount = 0,
    this.reviewCount = 0,
    this.pages,
    this.language,
    this.publisher,
    this.year,
  });

  final int id;
  final String title;
  final String author;
  final double price;
  final double rating;
  final String cover;
  final String category;
  final String description;
  final int stockQuantity;
  final int soldQuantity;
  final double discount;
  final int reviewCount;
  final int? pages;
  final String? language;
  final String? publisher;
  final int? year;

  factory Book.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl']?.toString() ?? '';
    final categoryName = json['categoryName']?.toString();
    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Book(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      price: parseDouble(json['price']),
      discount: parseDouble(json['discount']),
      rating: parseDouble(json['rating']),
      cover: imageUrl,
      category: categoryName?.isNotEmpty == true ? categoryName! : 'Tất cả',
      description: json['description']?.toString() ?? '',
      pages: json['pages'] as int?,
      language: json['language']?.toString(),
      publisher: json['publisher']?.toString(),
      year: json['year'] as int?,
      stockQuantity: parseInt(json['stockQuantity']),
      soldQuantity: parseInt(json['soldQuantity']),
      reviewCount: parseInt(json['reviewCount']),
    );
  }
}

