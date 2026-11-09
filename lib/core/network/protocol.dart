import 'dart:convert';

abstract final class WsTypes {
  static const hello = 'hello';
  static const mediaState = 'media.state';
  static const statusUpdate = 'status.update';
  static const ack = 'ack';
  static const pong = 'pong';
  static const error = 'error';
  static const bye = 'bye';
  static const ping = 'ping';

  static const mediaPlay = 'media.play';
  static const mediaPause = 'media.pause';
  static const mediaToggle = 'media.toggle';
  static const mediaNext = 'media.next';
  static const mediaPrev = 'media.prev';
  static const mediaSeek = 'media.seek';
  static const statusSubscribe = 'status.subscribe';
  static const statusUnsubscribe = 'status.unsubscribe';

  static const volumeState = 'volume.state';
  static const volumeSet = 'volume.set';
  static const volumeMute = 'volume.mute';
  static const volumeToggle = 'volume.toggle';
  static const volumeGet = 'volume.get';

  static const shelfFile = 'shelf.file';
  static const shelfText = 'shelf.text';
  static const shelfAck = 'shelf.ack';
}

class WsMessage {
  const WsMessage({required this.type, this.id, this.data});

  final String type;
  final String? id;
  final Map<String, dynamic>? data;

  factory WsMessage.decode(Object? raw) {
    if (raw is! String) {
      throw const FormatException('Expected a text frame.');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object.');
    }

    final type = decoded['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Missing "type".');
    }

    final id = decoded['id'];
    final data = decoded['data'];

    return WsMessage(
      type: type,
      id: id is String ? id : null,
      data: data is Map
          ? data.map((key, value) => MapEntry(key.toString(), value))
          : null,
    );
  }

  String encode() {
    return jsonEncode({
      'type': type,
      if (id != null) 'id': id,
      if (data != null) 'data': data,
    });
  }
}

class PcHello {
  const PcHello({
    required this.apiVersion,
    required this.pcName,
    required this.mediaAvailable,
  });

  final int apiVersion;
  final String pcName;
  final bool mediaAvailable;

  factory PcHello.fromData(Map<String, dynamic>? data) {
    final version = data?['apiVersion'];
    final name = data?['pcName'];

    return PcHello(
      apiVersion: version is num ? version.toInt() : 1,
      pcName: name is String ? name : '',
      mediaAvailable: data?['mediaAvailable'] == true,
    );
  }
}
