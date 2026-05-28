import 'package:json_annotation/json_annotation.dart';

part 'response_message_dto.g.dart';

@JsonSerializable()
class ResponseMessageDto {
  final String? message;

  ResponseMessageDto({
    this.message,
  });

  factory ResponseMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ResponseMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResponseMessageDtoToJson(this);
}
