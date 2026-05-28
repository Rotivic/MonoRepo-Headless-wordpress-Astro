// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponseUserDto _$ResponseUserDtoFromJson(Map<String, dynamic> json) =>
    ResponseUserDto(
      code: (json['code'] as num).toInt(),
      data: json['data'] == null
          ? null
          : UserDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ResponseUserDtoToJson(ResponseUserDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
      'error': instance.error,
    };
