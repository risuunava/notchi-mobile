import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/connection/ui/connection_lifecycle.dart';
import 'features/shell/ui/app_shell.dart';
import 'features/shelf/ui/share_intent_handler.dart';

class NotchiMobileApp extends ConsumerWidget {
  const NotchiMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp(
      title: 'Notchi',
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('id')],
      home: const ConnectionLifecycle(
        child: ShareIntentHandler(child: AppShell()),
      ),
    );
  }
}
