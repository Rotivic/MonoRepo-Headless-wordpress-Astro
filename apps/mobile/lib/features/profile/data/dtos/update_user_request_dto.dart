import 'package:json_annotation/json_annotation.dart';

part 'update_user_request_dto.g.dart';

@JsonSerializable()
class UpdateUserRequestDto {
  @JsonKey(name: 'first_name')
  final String firstName;

  @JsonKey(name: 'last_name')
  final String lastName;

  final String email;

  UpdateUserRequestDto({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory UpdateUserRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserRequestDtoToJson(this);
}
