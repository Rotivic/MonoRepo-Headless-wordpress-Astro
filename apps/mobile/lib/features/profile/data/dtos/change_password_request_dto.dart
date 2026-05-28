import 'package:json_annotation/json_annotation.dart';

part 'change_password_request_dto.g.dart';

@JsonSerializable()
class ChangePasswordRequestDto {
  @JsonKey(name: 'current_password')
  final String currentPassword;

  final String password;

  @JsonKey(name: 'password_confirmation')
  final String passwordConfirmation;

  ChangePasswordRequestDto({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirmation,
  });

  factory ChangePasswordRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordRequestDtoToJson(this);
}
