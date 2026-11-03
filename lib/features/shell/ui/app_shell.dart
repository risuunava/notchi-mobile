import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final index = ref.watch(shellTabProvider);
    final session = ref.watch(savedSessionProvider).asData?.value;

    // Show navbar whenever a paired session exists (even while reconnecting).
    // Only hide it before the user has ever paired.
    final hasPairedSession = session != null;

    final destinations = [
      _Destination(icon: LucideIcons.home, label: strings.navHome),
      _Destination(icon: LucideIcons.folder, label: strings.navFolder),
      _Destination(icon: LucideIcons.stickyNote, label: strings.navNote),
      _Destination(icon: LucideIcons.settings, label: strings.navSettings),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: hasPairedSession
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
