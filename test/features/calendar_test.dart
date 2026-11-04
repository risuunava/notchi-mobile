import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notchi_mobile/core/l10n/strings.dart';
import 'package:notchi_mobile/core/storage/secure_store.dart';
import 'package:notchi_mobile/features/pairing/state/session_providers.dart';
import 'package:notchi_mobile/features/pairing/ui/home_screen.dart';

void main() {
  const session = SavedSession(
    sessionToken: 'test-token',
    pcId: 'pc-1',
    pcName: 'MY-PC',
    host: '192.168.1.100',
    port: 8765,
    apiVersion: 1,
  );

  Widget createWidget({Locale locale = const Locale('id')}) {
    return ProviderScope(
      overrides: [
        savedSessionProvider.overrideWith((ref) => session),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Scaffold(
          body: HomeScreen(),
        ),
      ),
    );
  }

  testWidgets(
      'calendar has no scale icon, compacts on swipe up, and expands on swipe down or tap',
      (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    final now = DateTime.now();
    const strings = AppStrings('id');
    final expectedDay = strings.weekdaysFull[now.weekday - 1];
    final expectedMonth = strings.monthsFull[now.month - 1];
    final expectedYear = now.year.toString();
    final expectedDate = now.day.toString();

    // Pastikan TIDAK ada icon scale di pojok kanan atas kalender
    expect(find.byIcon(LucideIcons.minimize2), findsNothing);
    expect(find.byIcon(LucideIcons.maximize2), findsNothing);

    // Cari posisi kalender (misal teks bulan & tahun)
    final monthFinder = find.text('$expectedMonth $expectedYear');
    expect(monthFinder, findsOneWidget);
    final center = tester.getCenter(monthFinder);

    // Geser ke atas (swipe up) di bagian kalender
    await tester.dragFrom(Offset(center.dx, center.dy + 40), const Offset(0, -60));
    await tester.pumpAndSettle();

    // Pastikan scrollable tidak bergerak sama sekali (offset tetap 0.0)
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, 0.0);

    // Kalender langsung compact!
    // Menampilkan Hari, Tanggal, Bulan, Tahun tanpa icon chevron
    expect(find.text(expectedDay), findsOneWidget);
    expect(find.text('$expectedDate $expectedMonth $expectedYear'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsNothing);

    // Geser ke bawah (swipe down) di kalender compact -> kalender terbuka kembali
    final compactFinder = find.text(expectedDay);
    final compactCenter = tester.getCenter(compactFinder);
    await tester.dragFrom(compactCenter, const Offset(0, 60));
    await tester.pumpAndSettle();

    // Kalender kembali terbuka
    expect(find.text('$expectedMonth $expectedYear'), findsOneWidget);

    // Geser ke atas lagi untuk compact
    await tester.dragFrom(Offset(center.dx, center.dy + 40), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(find.text(expectedDay), findsOneWidget);

    // Tap pada kalender compact juga membuka kembali kalender
    await tester.tap(find.text(expectedDay), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('$expectedMonth $expectedYear'), findsOneWidget);
  });
}
