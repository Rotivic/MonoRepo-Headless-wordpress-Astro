// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUserRequestDto _$UpdateUserRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateUserRequestDto(
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$UpdateUserRequestDtoToJson(
  UpdateUserRequestDto instance,
) => <String, dynamic>{
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'email': instance.email,
};
