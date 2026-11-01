import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/connection/ui/connection_lifecycle.dart';
import 'features/pairing/ui/home_screen.dart';

class NotchiMobileApp extends StatelessWidget {
  const NotchiMobileApp({super.key});

  static const _seedColor = Color(0xFF7C4DFF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notchi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('id')],
      home: const ConnectionLifecycle(child: HomeScreen()),
    );
  }
}
