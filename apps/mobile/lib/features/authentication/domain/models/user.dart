class User {
  final int id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool enabled;
  final bool isVerified;

  User({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    required this.enabled,
    required this.isVerified,
  });
}
