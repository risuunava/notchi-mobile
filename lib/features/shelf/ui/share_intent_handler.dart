import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../state/shelf_controller.dart';

class ShareIntentHandler extends ConsumerStatefulWidget {
  const ShareIntentHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShareIntentHandler> createState() => _ShareIntentHandlerState();
}

class _ShareIntentHandlerState extends ConsumerState<ShareIntentHandler> {
  StreamSubscription<List<SharedMediaFile>>? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    // Only listen on Android and iOS (desktop/web do not support receive_sharing_intent)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      _initSharing();
    }
  }

  void _initSharing() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> files) {
          _handleSharedFiles(files);
        }, onError: (_) {});

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> files,
    ) {
      _handleSharedFiles(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    for (final shared in files) {
      if (shared.type == SharedMediaType.text ||
          shared.type == SharedMediaType.url) {
        if (shared.path.isNotEmpty) {
          ref.read(shelfControllerProvider.notifier).sendText(shared.path);
        }
      } else {
        if (shared.path.isNotEmpty) {
          ref
              .read(shelfControllerProvider.notifier)
              .sendFile(filePath: shared.path);
        }
      }
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
