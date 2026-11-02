import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notchi_mobile/app.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/connection/state/connection_providers.dart';
import 'package:notchi_mobile/features/media/model/media_state.dart';
import 'package:notchi_mobile/features/media/state/media_controller.dart';
import 'package:notchi_mobile/features/pairing/state/session_providers.dart';

import '../../helpers/fakes.dart';

void main() {
  const session = SavedSession(
    sessionToken: 'token',
    pcId: 'pc-1',
    pcName: 'LAPTOP-TEST',
    host: '192.168.1.10',
    port: 8765,
    apiVersion: 1,
  );

  testWidgets('renders standby message when media is null or unavailable', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await SessionStore(store).saveSession(session);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          wsConnectorProvider.overrideWithValue(FakeWsConnector()),
        ],
        child: const NotchiMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No media playing'), findsOneWidget);
    expect(
      find.text('Open a music or video app on the PC.'),
      findsOneWidget,
    );
  });

  testWidgets('renders active media info and triggers controls', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await SessionStore(store).saveSession(session);
    final connector = FakeWsConnector();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          wsConnectorProvider.overrideWithValue(connector),
          mediaControllerProvider.overrideWith(() {
            return _TestMediaController(
              const MediaState(
                available: true,
                title: 'Imagine',
                artist: 'John Lennon',
                album: 'Imagine Album',
                sourceApp: 'Spotify',
                playing: true,
                positionSeconds: 30.0,
                durationSeconds: 180.0,
                canSeek: true,
                artVersion: 1,
              ),
            );
          }),
        ],
        child: const NotchiMobileApp(),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.text('Imagine'), findsOneWidget);
    expect(find.text('John Lennon'), findsOneWidget);
    expect(find.byType(FaIcon), findsOneWidget);
    expect(find.byIcon(LucideIcons.pause), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Tap toggle/pause button
    await tester.tap(find.byIcon(LucideIcons.pause));
    await tester.pump();

    // Tap next button
    await tester.tap(find.byIcon(LucideIcons.skipForward));
    await tester.pump();

    // Tap prev button
    await tester.tap(find.byIcon(LucideIcons.skipBack));
    await tester.pump();
  });
}

class _TestMediaController extends MediaController {
  _TestMediaController(this._initial);

  final MediaState _initial;

  @override
  MediaState? build() => _initial;

  @override
  void toggle() {}

  @override
  void next() {}

  @override
  void previous() {}

  @override
  void seek(double positionSeconds) {}
}
