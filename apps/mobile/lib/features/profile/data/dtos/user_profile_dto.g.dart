// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: intFromJsonOrZero(json['id']),
      firstName: stringFromJson(json['first_name']),
      lastName: stringFromJson(json['last_name']),
      email: stringFromJson(json['email']),
      avatarUrl: stringFromJson(json['avatar_url']),
      createdAt: stringFromJson(json['created_at']),
      twoFactorEnabled: boolFromJson(json['two_factor_enabled']),
      isVerified: boolFromJson(json['is_verified']),
      isEnabled: boolFromJson(json['is_enabled']),
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => UserRoleDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt,
      'two_factor_enabled': instance.twoFactorEnabled,
      'is_verified': instance.isVerified,
      'is_enabled': instance.isEnabled,
      'roles': instance.roles,
    };
