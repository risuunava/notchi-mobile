import '../core/json/json_utils.dart';

class PairResult {
  const PairResult({
    required this.sessionToken,
    required this.pcId,
    required this.pcName,
  });

  final String sessionToken;
  final String pcId;
  final String pcName;

  factory PairResult.fromJson(Map<String, dynamic> json) {
    return PairResult(
      sessionToken: requiredJsonString(json, 'sessionToken'),
      pcId: requiredJsonString(json, 'pcId'),
      pcName: requiredJsonString(json, 'pcName'),
    );
  }
}
