import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../connection/state/connection_providers.dart';
import '../../connection/state/connection_status.dart';
import '../../notes/ui/notes_page.dart';
import '../../pairing/state/session_providers.dart';
import '../../pairing/ui/home_screen.dart';
import '../../settings/ui/settings_page.dart';
import '../../shelf/ui/shelf_page.dart';
import '../state/shell_tab_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = [
    HomeScreen(),
    ShelfPage(),
    NotesPage(),
    SettingsPage(),
  ];

  static const _issuesUrl = 'https://github.com/risuunava/Notchi/issues/new';

  Future<void> _openIssue(BuildContext context) async {
    final strings = AppStrings.of(context);
    var opened = false;

    try {
      opened = await launchUrl(
        Uri.parse(_issuesUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.linkOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final index = ref.watch(shellTabProvider);
    final session = ref.watch(savedSessionProvider).asData?.value;
    final status = ref.watch(connectionControllerProvider);
    final connected = session != null && status is ConnectionConnected;

    final destinations = [
      _Destination(icon: LucideIcons.home, label: strings.navHome),
      _Destination(icon: LucideIcons.folder, label: strings.navFolder),
      _Destination(icon: LucideIcons.stickyNote, label: strings.navNote),
      _Destination(icon: LucideIcons.settings, label: strings.navSettings),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: index, children: _pages),
          if (!connected)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 14),
                  child: _ReportIssueButton(
                    tooltip: strings.reportConnectionIssue,
                    onTap: () => _openIssue(context),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: connected
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 66,
                  child: Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _NavItem(
                            destination: destinations[i],
                            selected: index == i,
                            onTap: () =>
                                ref.read(shellTabProvider.notifier).select(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _ReportIssueButton extends StatelessWidget {
  const _ReportIssueButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              LucideIcons.circleAlert,
              size: 21,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.muted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(destination.icon, size: 21, color: color),
          const SizedBox(height: 5),
          Text(
            destination.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
