class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.role,
  });

  final String token;
  final int userId;
  final String role;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token']?.toString() ?? '',
      userId: int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      role: json['role']?.toString() ?? 'customer',
    );
  }
}
