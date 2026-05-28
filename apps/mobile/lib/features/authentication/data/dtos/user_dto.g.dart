// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  enabled: json['enabled'] as bool?,
  isVerified: json['is_verified'] as bool?,
  isAdmin: json['is_admin'] as bool?,
  isSuperadmin: json['is_superadmin'] as bool?,
  avatarUrl: json['avatar_url'] as String?,
  createdAt: json['created_at'] as String?,
  twoFactorEnabled: json['two_factor_enabled'] as bool?,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'enabled': instance.enabled,
  'is_verified': instance.isVerified,
  'is_admin': instance.isAdmin,
  'is_superadmin': instance.isSuperadmin,
  'avatar_url': instance.avatarUrl,
  'created_at': instance.createdAt,
  'two_factor_enabled': instance.twoFactorEnabled,
};
