class SystemStatus {
  const SystemStatus({
    this.cpuPercent,
    this.ramPercent,
    this.diskPercent,
    this.battery,
    this.timestamp,
  });

  final double? cpuPercent;
  final double? ramPercent;
  final double? diskPercent;
  final BatteryInfo? battery;
  final DateTime? timestamp;

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      cpuPercent: (json['cpuPercent'] as num?)?.toDouble(),
      ramPercent: (json['ramPercent'] as num?)?.toDouble(),
      diskPercent: (json['diskPercent'] as num?)?.toDouble(),
      battery: json['battery'] is Map
          ? BatteryInfo.fromJson(
              (json['battery'] as Map).map((k, v) => MapEntry(k.toString(), v)),
            )
          : null,
      timestamp: json['timestamp'] is String
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cpuPercent != null) 'cpuPercent': cpuPercent,
      if (ramPercent != null) 'ramPercent': ramPercent,
      if (diskPercent != null) 'diskPercent': diskPercent,
      if (battery != null) 'battery': battery!.toJson(),
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}

class BatteryInfo {
  const BatteryInfo({required this.percent, required this.charging});

  final int percent;
  final bool charging;

  factory BatteryInfo.fromJson(Map<String, dynamic> json) {
    return BatteryInfo(
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      charging: json['charging'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'percent': percent, 'charging': charging};
  }
}
