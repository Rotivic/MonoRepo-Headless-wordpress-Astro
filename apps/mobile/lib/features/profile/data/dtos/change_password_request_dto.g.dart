// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_password_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangePasswordRequestDto _$ChangePasswordRequestDtoFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequestDto(
  currentPassword: json['current_password'] as String,
  password: json['password'] as String,
  passwordConfirmation: json['password_confirmation'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestDtoToJson(
  ChangePasswordRequestDto instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'password': instance.password,
  'password_confirmation': instance.passwordConfirmation,
};
