import 'package:json_annotation/json_annotation.dart';

part 'transporttype.g.dart';

@JsonSerializable()
class TransportType {
  final int id;
  final String name;
  final String? description;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  TransportType({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory TransportType.fromJson(Map<String, dynamic> json) =>
      _$TransportTypeFromJson(json);

  Map<String, dynamic> toJson() => _$TransportTypeToJson(this);
}
