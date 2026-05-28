class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String? createdAt;
  final bool twoFactorEnabled;
  final bool isVerified;
  final bool isEnabled;
  final List<String> roles;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    this.createdAt,
    required this.twoFactorEnabled,
    required this.isVerified,
    required this.isEnabled,
    required this.roles,
  });

  String get fullName => '$firstName $lastName'.trim();

  UserProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    String? createdAt,
    bool? twoFactorEnabled,
    bool? isVerified,
    bool? isEnabled,
    List<String>? roles,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      isVerified: isVerified ?? this.isVerified,
      isEnabled: isEnabled ?? this.isEnabled,
      roles: roles ?? this.roles,
    );
  }
}
