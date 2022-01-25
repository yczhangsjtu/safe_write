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
    (json['pageBreaks'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, (e as List<dynamic>).map((e) => e as int).toList()),
    ),
    Map<String, int>.from(json['passages'] as Map),
  );
}

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'files': instance.files,
      'locations': instance.locations,
      'pageBreaks': instance.pageBreaks,
      'passages': instance.passages,
    };
