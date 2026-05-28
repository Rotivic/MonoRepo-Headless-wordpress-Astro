import 'package:json_annotation/json_annotation.dart';
import 'package:tcg_platform_mobile/core/utils/json_parsers.dart';

part 'dropdown_dto.g.dart';

@JsonSerializable()
class DropdownResponseDto {
  final int code;
  final List<DropdownItemDto>? data;
  final String? error;

  DropdownResponseDto({
    required this.code,
    this.data,
    this.error,
  });

  factory DropdownResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DropdownResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DropdownResponseDtoToJson(this);
}

@JsonSerializable()
class DropdownItemDto {
  @JsonKey(name: 'id', fromJson: intFromJsonOrZero)
  final int id;

  @JsonKey(name: 'label', fromJson: stringFromJson)
  final String? label;

  @JsonKey(name: 'value', fromJson: intFromJsonOrZero)
  final int value;

  DropdownItemDto({
    required this.id,
    this.label,
    required this.value,
  });

  factory DropdownItemDto.fromJson(Map<String, dynamic> json) =>
      _$DropdownItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DropdownItemDtoToJson(this);
}
