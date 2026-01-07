class OrderReview {
  const OrderReview({
    required this.id,
    required this.orderItemId,
    required this.bookId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.anonymous,
    required this.images,
    required this.videos,
  });

  final int id;
  final int orderItemId;
  final int bookId;
  final String userName;
  final double rating;
  final String comment;
  final bool anonymous;
  final List<String> images;
  final List<String> videos;

  factory OrderReview.fromJson(Map<String, dynamic> json) {
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

    return OrderReview(
      id: json['id'] as int? ?? 0,
      orderItemId: json['orderItemId'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      userName: json['userName']?.toString() ?? '',
      rating: parseDouble(json['rating']),
      comment: json['comment']?.toString() ?? '',
      anonymous: json['anonymous'] == true,
      images: parseMedia(json['images']),
      videos: parseMedia(json['videos']),
    );
  }
}
