import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class Settings {
  @JsonKey(required: true)
  final List<String> files;

  @JsonKey(required: true)
  final Map<String, int> locations;

  @JsonKey(required: false)
  final Map<String, List<int>> pageBreaks;

  @JsonKey(required: true)
  final Map<String, int> passages;

  Settings(this.files, this.locations, this.pageBreaks, this.passages);

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}
