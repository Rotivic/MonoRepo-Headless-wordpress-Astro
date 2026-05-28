import 'package:json_annotation/json_annotation.dart';

part 'user_response_dto.g.dart';

@JsonSerializable()
class UserResponseDto {
  final Map<String, dynamic> data;

  UserResponseDto({required this.data});

  factory UserResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseDtoToJson(this);
}
