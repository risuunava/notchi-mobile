import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pairing/state/session_providers.dart';

class LocaleController extends Notifier<Locale> {
  static const _localeKey = 'notchi.locale';
  static const supportedLanguageCodes = {'en', 'id'};

  @override
  Locale build() {
    _restore();
    return const Locale('en');
  }

  Future<void> _restore() async {
    try {
      final stored = await ref.read(keyValueStoreProvider).read(_localeKey);
      if (stored != null && supportedLanguageCodes.contains(stored)) {
        state = Locale(stored);
      }
    } catch (_) {
      // Keep the default locale when the stored value cannot be read.
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode)) return;
    state = Locale(languageCode);
    try {
      await ref.read(keyValueStoreProvider).write(_localeKey, languageCode);
    } catch (_) {
      // The UI already switched language; persistence is best effort.
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
