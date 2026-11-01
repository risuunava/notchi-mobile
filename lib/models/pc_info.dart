import '../core/json/json_utils.dart';

class PcInfo {
  const PcInfo({
    required this.apiVersion,
    required this.appVersion,
    required this.pcId,
    required this.pcName,
  });

  final int apiVersion;
  final String appVersion;
  final String pcId;
  final String pcName;

  factory PcInfo.fromJson(Map<String, dynamic> json) {
    return PcInfo(
      apiVersion: requiredJsonInt(json, 'apiVersion'),
      appVersion: requiredJsonString(json, 'appVersion'),
      pcId: requiredJsonString(json, 'pcId'),
      pcName: requiredJsonString(json, 'pcName'),
    );
  }
}
