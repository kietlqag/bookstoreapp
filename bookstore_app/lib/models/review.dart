class Review {
  const Review({
    required this.id,
    required this.bookId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.images,
    required this.videos,
    required this.createdAt,
  });

  final int id;
  final int bookId;
  final String userName;
  final double rating;
  final String comment;
  final List<String> images;
  final List<String> videos;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final createdAt = json['createdAt'];
    if (createdAt is String) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        parsedDate = parsed.toLocal();
      }
    }
    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }
    List<String> parseMedia(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }
    return Review(
      id: json['id'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      userName: json['userName']?.toString() ?? '',
      rating: parseDouble(json['rating']),
      comment: json['comment']?.toString() ?? '',
      images: parseMedia(json['images']),
      videos: parseMedia(json['videos']),
      createdAt: parsedDate,
    );
  }
}
