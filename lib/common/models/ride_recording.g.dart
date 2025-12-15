// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_recording.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RideRecording _$RideRecordingFromJson(Map<String, dynamic> json) =>
    RideRecording(
      id: json['id'] as String,
      rideId: json['rideId'] as String?,
      userId: json['userId'] as String,
      filePath: json['filePath'] as String,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime:
          json['endTime'] == null
              ? null
              : DateTime.parse(json['endTime'] as String),
      isUploaded: json['isUploaded'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RideRecordingToJson(RideRecording instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rideId': instance.rideId,
      'userId': instance.userId,
      'filePath': instance.filePath,
      'fileSize': instance.fileSize,
      'duration': instance.duration,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'isUploaded': instance.isUploaded,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
