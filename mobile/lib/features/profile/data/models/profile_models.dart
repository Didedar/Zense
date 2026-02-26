class ProfileRead {
  final String id;
  final String userId;
  final String displayName;
  final int? age;
  final String segment;
  final String currency;
  final String timezone;
  final bool onboardingCompleted;
  final String spendingStyle;
  final DateTime createdAt;

  const ProfileRead({
    required this.id,
    required this.userId,
    required this.displayName,
    this.age,
    required this.segment,
    required this.currency,
    required this.timezone,
    required this.onboardingCompleted,
    required this.spendingStyle,
    required this.createdAt,
  });

  factory ProfileRead.fromJson(Map<String, dynamic> json) => ProfileRead(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        displayName: json['display_name'] as String? ?? '',
        age: json['age'] as int?,
        segment: json['segment'] as String? ?? 'student',
        currency: json['currency'] as String? ?? 'KZT',
        timezone: json['timezone'] as String? ?? 'Asia/Almaty',
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
        spendingStyle: json['spending_style'] as String? ?? 'medium',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
