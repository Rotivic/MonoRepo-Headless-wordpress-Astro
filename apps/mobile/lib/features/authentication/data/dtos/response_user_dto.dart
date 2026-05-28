import 'package:json_annotation/json_annotation.dart';
import 'package:tcg_platform_mobile/features/authentication/data/dtos/user_dto.dart';

part 'response_user_dto.g.dart';

@JsonSerializable()
class ResponseUserDto {
  final int code;
  final UserDto? data;
  final String? error;

  ResponseUserDto({
    required this.code,
    this.data,
    this.error,
  });

  factory ResponseUserDto.fromJson(Map<String, dynamic> json) =>
      _$ResponseUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResponseUserDtoToJson(this);
}
