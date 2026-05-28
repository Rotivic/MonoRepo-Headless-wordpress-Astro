import 'package:json_annotation/json_annotation.dart';
import 'package:tcg_platform_mobile/core/utils/json_parsers.dart';

part 'user_role_dto.g.dart';

@JsonSerializable()
class UserRoleDto {
  @JsonKey(name: 'id', fromJson: stringFromJson)
  final String? id;

  @JsonKey(name: 'title', fromJson: stringFromJson)
  final String? title;

  UserRoleDto({
    this.id,
    this.title,
  });

  factory UserRoleDto.fromJson(Map<String, dynamic> json) =>
      _$UserRoleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserRoleDtoToJson(this);
}
