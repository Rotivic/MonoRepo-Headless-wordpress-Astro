import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  const UserDto({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.enabled,
    this.isVerified,
    this.isAdmin,
    this.isSuperadmin,
    this.avatarUrl,
    this.createdAt,
    this.twoFactorEnabled,
  });

  final int id;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  final bool? enabled;

  @JsonKey(name: 'is_verified')
  final bool? isVerified;

  @JsonKey(name: 'is_admin')
  final bool? isAdmin;

  @JsonKey(name: 'is_superadmin')
  final bool? isSuperadmin;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'two_factor_enabled')
  final bool? twoFactorEnabled;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
