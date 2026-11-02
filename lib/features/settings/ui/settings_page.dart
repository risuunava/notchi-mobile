import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/errors/api_error.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../connection/state/connection_providers.dart';
import '../../connection/state/connection_status.dart';
import '../../pairing/state/pairing_providers.dart';
import '../../pairing/state/session_providers.dart';
import '../../pairing/ui/connect_first_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final session = ref.watch(savedSessionProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: [
          Text(
            strings.settingsTitle,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            strings.settingsSubtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: strings.connectionSection),
          const SizedBox(height: 10),
          session.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const _DisconnectedCard(),
            data: (value) => value == null
                ? const _DisconnectedCard()
                : _ConnectedSettings(
                    session: value,
                    strings: strings,
                    onDisconnect: () =>
                        _disconnect(context, ref, strings, value),
                  ),
          ),
          const SizedBox(height: 26),
          _SectionLabel(label: strings.languageSection),
          const SizedBox(height: 10),
          const _LanguageCard(),
          const SizedBox(height: 26),
          _SectionLabel(label: strings.aboutSection),
          const SizedBox(height: 10),
          _InfoCard(
            rows: [
              _InfoRow(
                icon: LucideIcons.appWindow,
                label: strings.appVersionLabel,
                value: '0.1.0',
              ),
              _InfoRow(
                icon: LucideIcons.server,
                label: strings.apiVersionLabel,
                value: 'v1',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    SavedSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.disconnectTitle),
        content: Text(strings.disconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.disconnectDevice),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    var remoteFailed = false;
    try {
      await ref
          .read(apiClientProvider)
          .deleteDevice(
            host: session.host,
            port: session.port,
            sessionToken: session.sessionToken,
          );
    } on ApiError catch (error) {
      remoteFailed = error.code != ApiErrorCode.invalidToken;
    } catch (_) {
      remoteFailed = true;
    }

    await ref.read(sessionStoreProvider).clearSession();
    ref.invalidate(savedSessionProvider);

    if (remoteFailed && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.disconnectFailed)));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _DisconnectedCard extends StatelessWidget {
  const _DisconnectedCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strings.connectionOffline,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const ConnectFirstCard(),
      ],
    );
  }
}

class _ConnectedSettings extends ConsumerWidget {
  const _ConnectedSettings({
    required this.session,
    required this.strings,
    required this.onDisconnect,
  });

  final SavedSession session;
  final AppStrings strings;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionControllerProvider);
    final meta = _statusMeta(status, strings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.laptop,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.pcName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: meta.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meta.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${session.host}:${session.port}',
                style: const TextStyle(
                  color: Color(0xC7FFFFFF),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          rows: [
            _InfoRow(
              icon: LucideIcons.wifi,
              label: strings.ipAddressLabel,
              value: session.host,
            ),
            _InfoRow(
              icon: LucideIcons.network,
              label: strings.portLabelShort,
              value: '${session.port}',
            ),
            _InfoRow(
              icon: LucideIcons.badgeCheck,
              label: strings.apiVersionLabel,
              value: 'v${session.apiVersion}',
            ),
            _InfoRow(
              icon: LucideIcons.fingerprint,
              label: 'PC ID',
              value: session.pcId,
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDisconnect,
          icon: const Icon(LucideIcons.link2Off, size: 17),
          label: Text(strings.disconnectDevice),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.28)),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  _StatusMeta _statusMeta(ConnectionStatus status, AppStrings strings) {
    return switch (status) {
      ConnectionConnected() => _StatusMeta(
        Colors.white,
        strings.connectionOnline,
      ),
      ConnectionConnecting() => _StatusMeta(
        const Color(0x99FFFFFF),
        strings.connectionConnecting,
      ),
      ConnectionReconnecting() => _StatusMeta(
        const Color(0x99FFFFFF),
        strings.connectionReconnecting,
      ),
      ConnectionStopped(:final reason) => _StatusMeta(
        AppColors.danger,
        switch (reason) {
          ConnectionStopReason.revoked => strings.connectionRevoked,
          ConnectionStopReason.disabled => strings.connectionDisabled,
          ConnectionStopReason.unauthorized => strings.connectionUnauthorized,
        },
      ),
      ConnectionIdle() => _StatusMeta(
        const Color(0x99FFFFFF),
        strings.connectionOffline,
      ),
    };
  }
}

class _StatusMeta {
  const _StatusMeta(this.color, this.label);

  final Color color;
  final String label;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 52),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final current = Localizations.localeOf(context).languageCode;
    final currentLabel = current == 'id'
        ? strings.languageIndonesian
        : strings.languageEnglish;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(
          LucideIcons.languages,
          size: 20,
          color: AppColors.ink,
        ),
        title: Text(
          strings.languageSection,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          currentLabel,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        trailing: const Icon(
          LucideIcons.chevronDown,
          size: 18,
          color: AppColors.muted,
        ),
        onTap: () => _showLanguageSheet(context, ref, strings),
      ),
    );
  }

  Future<void> _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final current = Localizations.localeOf(context).languageCode;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.languages, size: 20),
              title: Text(strings.languageSection),
              subtitle: Text(strings.settingsSubtitle),
            ),
            ListTile(
              leading: Icon(
                current == 'en' ? LucideIcons.checkCircle : LucideIcons.circle,
                size: 20,
              ),
              title: Text(strings.languageEnglish),
              onTap: () {
                ref.read(localeControllerProvider.notifier).setLanguage('en');
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              leading: Icon(
                current == 'id' ? LucideIcons.checkCircle : LucideIcons.circle,
                size: 20,
              ),
              title: Text(strings.languageIndonesian),
              onTap: () {
                ref.read(localeControllerProvider.notifier).setLanguage('id');
                Navigator.of(sheetContext).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
