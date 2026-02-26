class TokenPair {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
      );
}

class UserRead {
  final String id;
  final String email;
  final bool isActive;
  final DateTime createdAt;

  const UserRead({
    required this.id,
    required this.email,
    required this.isActive,
    required this.createdAt,
  });

  factory UserRead.fromJson(Map<String, dynamic> json) => UserRead(
        id: json['id'] as String,
        email: json['email'] as String,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
