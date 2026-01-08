class ProfileSummary {
  const ProfileSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.avatar,
    required this.orderCount,
    required this.pendingCount,
    required this.waitingPickupCount,
    required this.shippingCount,
    required this.deliveredCount,
    required this.reviewPendingCount,
    required this.cancelledCount,
    required this.bookCount,
    required this.favoriteCount,
    required this.totalSpend,
    required this.monthlySpend,
  });

  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final String avatar;
  final int orderCount;
  final int pendingCount;
  final int waitingPickupCount;
  final int shippingCount;
  final int deliveredCount;
  final int reviewPendingCount;
  final int cancelledCount;
  final int bookCount;
  final int favoriteCount;
  final double totalSpend;
  final double monthlySpend;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      orderCount: int.tryParse(json['orderCount']?.toString() ?? '') ?? 0,
      pendingCount: int.tryParse(json['pendingCount']?.toString() ?? '') ?? 0,
      waitingPickupCount:
          int.tryParse(json['waitingPickupCount']?.toString() ?? '') ?? 0,
      shippingCount: int.tryParse(json['shippingCount']?.toString() ?? '') ?? 0,
      deliveredCount:
          int.tryParse(json['deliveredCount']?.toString() ?? '') ?? 0,
      reviewPendingCount:
          int.tryParse(json['reviewPendingCount']?.toString() ?? '') ?? 0,
      cancelledCount:
          int.tryParse(json['cancelledCount']?.toString() ?? '') ?? 0,
      bookCount: int.tryParse(json['bookCount']?.toString() ?? '') ?? 0,
      favoriteCount:
          int.tryParse(json['favoriteCount']?.toString() ?? '') ?? 0,
      totalSpend: double.tryParse(json['totalSpend']?.toString() ?? '') ?? 0.0,
      monthlySpend:
          double.tryParse(json['monthlySpend']?.toString() ?? '') ?? 0.0,
    );
  }
}
