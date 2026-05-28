import 'package:json_annotation/json_annotation.dart';
import 'package:tcg_platform_mobile/core/utils/json_parsers.dart';
import 'package:tcg_platform_mobile/features/profile/data/dtos/user_role_dto.dart';

part 'user_profile_dto.g.dart';

@JsonSerializable()
class UserProfileDto {
  @JsonKey(name: 'id', fromJson: intFromJsonOrZero)
  final int id;

  @JsonKey(name: 'first_name', fromJson: stringFromJson)
  final String? firstName;

  @JsonKey(name: 'last_name', fromJson: stringFromJson)
  final String? lastName;

  @JsonKey(name: 'email', fromJson: stringFromJson)
  final String? email;

  @JsonKey(name: 'avatar_url', fromJson: stringFromJson)
  final String? avatarUrl;

  @JsonKey(name: 'created_at', fromJson: stringFromJson)
  final String? createdAt;

  @JsonKey(name: 'two_factor_enabled', fromJson: boolFromJson)
  final bool twoFactorEnabled;

  @JsonKey(name: 'is_verified', fromJson: boolFromJson)
  final bool isVerified;

  @JsonKey(name: 'is_enabled', fromJson: boolFromJson)
  final bool isEnabled;

  @JsonKey(name: 'roles')
  final List<UserRoleDto>? roles;

  UserProfileDto({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.avatarUrl,
    this.createdAt,
    required this.twoFactorEnabled,
    required this.isVerified,
    required this.isEnabled,
    this.roles,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}
