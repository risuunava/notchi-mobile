import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notchi_mobile/app.dart';
import 'package:notchi_mobile/core/errors/api_error.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/connection/state/connection_providers.dart';
import 'package:notchi_mobile/features/pairing/state/pairing_providers.dart';
import 'package:notchi_mobile/features/pairing/state/session_providers.dart';
import 'package:notchi_mobile/features/pairing/ui/pairing_progress_screen.dart';

import 'helpers/fakes.dart';

Widget _app(Widget child, {required List<Override> overrides}) {
  return ProviderScope(overrides: overrides, child: child);
}

void main() {
  testWidgets('home asks to pair when no session is stored', (tester) async {
    final store = InMemoryKeyValueStore();

    await tester.pumpWidget(
      _app(
        const NotchiMobileApp(),
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Connect manually'), findsOneWidget);
    expect(find.text('Setting'), findsNothing);
    expect(find.byTooltip('Report connection issue'), findsOneWidget);
  });

  testWidgets('home shows the stored PC after pairing', (tester) async {
    final store = InMemoryKeyValueStore();
    await SessionStore(
      store,
      deviceNameResolver: () async => 'Android',
    ).saveSession(
      const SavedSession(
        sessionToken: 'token',
        pcId: 'pc-1',
        pcName: 'LAPTOP-TEST',
        host: '192.168.1.10',
        port: 8765,
        apiVersion: 1,
      ),
    );

    await tester.pumpWidget(
      _app(
        const NotchiMobileApp(),
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          wsConnectorProvider.overrideWithValue(FakeWsConnector()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected to LAPTOP-TEST'), findsOneWidget);
    expect(find.text('192.168.1.10:8765'), findsOneWidget);
    expect(find.text('PC Information'), findsOneWidget);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.byTooltip('Report connection issue'), findsNothing);
  });

  testWidgets('forget revokes the device and clears the local session', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await SessionStore(store).saveSession(
      const SavedSession(
        sessionToken: 'token',
        pcId: 'pc-1',
        pcName: 'LAPTOP-TEST',
        host: '192.168.1.10',
        port: 8765,
        apiVersion: 1,
      ),
    );
    final api = FakeApi();

    await tester.pumpWidget(
      _app(
        const NotchiMobileApp(),
        overrides: [
          apiClientProvider.overrideWithValue(api),
          keyValueStoreProvider.overrideWithValue(store),
          wsConnectorProvider.overrideWithValue(FakeWsConnector()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setting'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Disconnect'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
    await tester.pumpAndSettle();

    expect(api.deleteCalls, 1);
    expect(api.lastSessionToken, 'token');
    expect(await SessionStore(store).readSession(), isNull);
    expect(find.text('Not connected'), findsOneWidget);
  });

  testWidgets('forget clears the session even when the PC is unreachable', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    await SessionStore(store).saveSession(
      const SavedSession(
        sessionToken: 'token',
        pcId: 'pc-1',
        pcName: 'LAPTOP-TEST',
        host: '192.168.1.10',
        port: 8765,
        apiVersion: 1,
      ),
    );
    final api = FakeApi(deleteError: const ApiError(ApiErrorCode.network));

    await tester.pumpWidget(
      _app(
        const NotchiMobileApp(),
        overrides: [
          apiClientProvider.overrideWithValue(api),
          keyValueStoreProvider.overrideWithValue(store),
          wsConnectorProvider.overrideWithValue(FakeWsConnector()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setting'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Disconnect'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
    await tester.pumpAndSettle();

    expect(api.deleteCalls, 1);
    expect(await SessionStore(store).readSession(), isNull);
    expect(
      find.text(
        'Disconnected from this phone, but the PC was unreachable. '
        'Also revoke this device in Notchi PC settings.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('manual pairing reaches the success state', (tester) async {
    await tester.pumpWidget(
      _app(
        const MaterialApp(
          home: PairingProgressScreen.manual(
            host: '192.168.1.10',
            port: '8765',
            token: 'tok-1',
          ),
        ),
        overrides: [
          apiClientProvider.overrideWithValue(FakeApi()),
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paired successfully'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('manual pairing shows a localized server error', (tester) async {
    await tester.pumpWidget(
      _app(
        const MaterialApp(
          home: PairingProgressScreen.manual(
            host: '192.168.1.10',
            port: '8765',
            token: 'tok-1',
          ),
        ),
        overrides: [
          apiClientProvider.overrideWithValue(
            FakeApi(pairError: ApiError(ApiErrorCode.pairingDenied)),
          ),
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connection failed'), findsOneWidget);
    expect(find.text('The request was denied on the PC.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
