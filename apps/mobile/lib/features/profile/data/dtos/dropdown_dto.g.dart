// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dropdown_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DropdownResponseDto _$DropdownResponseDtoFromJson(Map<String, dynamic> json) =>
    DropdownResponseDto(
      code: (json['code'] as num).toInt(),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => DropdownItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DropdownResponseDtoToJson(
  DropdownResponseDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'data': instance.data,
  'error': instance.error,
};

DropdownItemDto _$DropdownItemDtoFromJson(Map<String, dynamic> json) =>
    DropdownItemDto(
      id: intFromJsonOrZero(json['id']),
      label: stringFromJson(json['label']),
      value: intFromJsonOrZero(json['value']),
    );

Map<String, dynamic> _$DropdownItemDtoToJson(DropdownItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'value': instance.value,
    };
