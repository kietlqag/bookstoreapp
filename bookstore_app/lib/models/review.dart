class Review {
  const Review({
    required this.id,
    required this.bookId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final int bookId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final createdAt = json['createdAt'];
    if (createdAt is String) {
      parsedDate = DateTime.tryParse(createdAt);
    }
    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }
    return Review(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      userName: json['userName']?.toString() ?? '',
      rating: parseDouble(json['rating']),
      comment: json['comment']?.toString() ?? '',
      createdAt: parsedDate,
    );
  }
}
