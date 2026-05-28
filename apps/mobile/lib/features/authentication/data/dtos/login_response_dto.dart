import 'package:json_annotation/json_annotation.dart';

part 'login_response_dto.g.dart';

@JsonSerializable()
class LoginResponseDto {
  final String? token;
  @JsonKey(name: 'two_factor')
  final bool? twoFactor;
  @JsonKey(name: 'challenge_token')
  final String? challengeToken;

  LoginResponseDto({
    this.token,
    this.twoFactor,
    this.challengeToken,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}
