// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      token: json['token'] as String?,
      twoFactor: json['two_factor'] as bool?,
      challengeToken: json['challenge_token'] as String?,
    );

Map<String, dynamic> _$LoginResponseDtoToJson(LoginResponseDto instance) =>
    <String, dynamic>{
      'token': instance.token,
      'two_factor': instance.twoFactor,
      'challenge_token': instance.challengeToken,
    };
