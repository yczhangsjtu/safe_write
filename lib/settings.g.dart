// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['files', 'locations', 'passages']);
  return Settings(
    (json['files'] as List<dynamic>).map((e) => e as String).toList(),
    Map<String, int>.from(json['locations'] as Map),
    Map<String, int>.from(json['passages'] as Map),
  );
}

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'files': instance.files,
      'locations': instance.locations,
      'passages': instance.passages,
    };
