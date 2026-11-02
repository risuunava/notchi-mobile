import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../connection/state/connection_providers.dart';
import '../../connection/state/connection_status.dart';
import '../../media/state/media_controller.dart';
import '../../media/ui/media_player_card.dart';
import '../../shelf/state/shelf_controller.dart';
import '../../shell/state/shell_tab_controller.dart';
import '../../status/ui/system_status_card.dart';
import '../state/session_providers.dart';
import 'manual_connect_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final session = ref.watch(savedSessionProvider);

    return session.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _NotPairedView(strings: strings),
      data: (value) => value == null
          ? _NotPairedView(strings: strings)
          : _ConnectedHome(session: value),
    );
  }
}

class _NotPairedView extends StatelessWidget {
  const _NotPairedView({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.soft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.qrCode,
                  size: 32,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                strings.notPairedTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                strings.notPairedBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _open(context, const ScanScreen()),
                  icon: const Icon(LucideIcons.scanLine, size: 18),
                  label: Text(strings.scanQr),
                ),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => _open(context, const ManualConnectScreen()),
                icon: const Icon(LucideIcons.keyboard, size: 17),
                label: Text(strings.manualConnect),
              ),
              const SizedBox(height: 20),
              Text(
                strings.homeSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _ConnectedHome extends ConsumerStatefulWidget {
  const _ConnectedHome({required this.session});

  final SavedSession session;

  @override
  ConsumerState<_ConnectedHome> createState() => _ConnectedHomeState();
}

class _ConnectedHomeState extends ConsumerState<_ConnectedHome> {
  bool _collapsed = false;

  void _onVerticalDragEnd(DragEndDetails details) {
    final vy = details.primaryVelocity ?? 0;
    if (vy < -250) {
      if (!_collapsed) setState(() => _collapsed = true);
    } else if (vy > 250) {
      if (_collapsed) setState(() => _collapsed = false);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta != null) {
      if (details.primaryDelta! < -8 && !_collapsed) {
        setState(() => _collapsed = true);
      } else if (details.primaryDelta! > 8 && _collapsed) {
        setState(() => _collapsed = false);
      }
    }
  }

  void _toggleCollapsed() {
    setState(() => _collapsed = !_collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final status = ref.watch(connectionControllerProvider);
    final dropCount = ref.watch(shelfControllerProvider).history.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          behavior: HitTestBehavior.translucent,
          child: _Header(
            status: status,
            dropCount: dropCount,
            collapsed: _collapsed,
            onToggleCollapse: _toggleCollapsed,
            onPillTap: () =>
                ref.read(shellTabProvider.notifier).select(dropCount > 0 ? 1 : 3),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(title: strings.servicesTitle),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final service in _services(strings))
                        _ServiceChip(
                          service: service,
                          onTap: () => _openLink(context, service.url),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _SectionTitle(title: strings.pcInfoTitle),
                  const SizedBox(height: 14),
                  _PcInfoCard(session: widget.session),
                  const SizedBox(height: 12),
                  const SystemStatusCard(),
                  const SizedBox(height: 24),
                  Text(
                    strings.homeSubtitle,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_ServiceLink> _services(AppStrings strings) {
    return [
      _ServiceLink(
        icon: LucideIcons.bug,
        label: strings.serviceIssue,
        url: 'https://github.com/risuunava/Notchi/issues/new',
      ),
      _ServiceLink(
        icon: LucideIcons.code,
        label: strings.serviceSource,
        url: 'https://github.com/risuunava/Notchi',
      ),
      _ServiceLink(
        icon: LucideIcons.monitor,
        label: strings.serviceWindows,
        url: 'https://github.com/Arennbukangula/notchi-web',
      ),
      _ServiceLink(
        icon: LucideIcons.smartphone,
        label: strings.serviceMobile,
        url: 'https://github.com/risuunava/notchi-mobile',
      ),
    ];
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final strings = AppStrings.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
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
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.status,
    required this.dropCount,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.onPillTap,
  });

  final ConnectionStatus status;
  final int dropCount;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onPillTap;

  LinearGradient _headerGradient(String? sourceApp) {
    final app = sourceApp?.toLowerCase() ?? '';

    if (app.contains('chrome')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B0B0D), Color(0xFF3A0A0D), Color(0xFFB3121B)],
      );
    }

    if (app.contains('spotify')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF07100B), Color(0xFF0C2C1B), Color(0xFF1DB954)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0E0E10), Color(0xFF232326), Color(0xFF3A3A3F)],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final sourceApp = ref.watch(mediaControllerProvider)?.sourceApp;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(gradient: _headerGradient(sourceApp)),
            child: Stack(
              children: [
                const Positioned(
                  top: -110,
                  right: -80,
                  child: _Glow(size: 260, opacity: 0.14),
                ),
                const Positioned(
                  bottom: -130,
                  left: -100,
                  child: _Glow(size: 280, opacity: 0.08),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    collapsed ? 14 : 22,
                    18,
                    collapsed ? 12 : 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: collapsed
                              ? const SizedBox.shrink(key: ValueKey('empty_top'))
                              : Column(
                                  key: const ValueKey('full_top'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _DateTimeHeader(),
                                    const SizedBox(height: 18),
                                    _StatusPill(
                                      dropCount: dropCount,
                                      status: status,
                                      strings: strings,
                                      onTap: onPillTap,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                ),
                        ),
                      ),
                      const MediaPlayerCard(),
                      const SizedBox(height: 6),
                      Center(
                        child: GestureDetector(
                          onTap: onToggleCollapse,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 300),
                              turns: collapsed ? 0.5 : 0.0,
                              curve: Curves.easeInOut,
                              child: const Icon(
                                LucideIcons.chevronUp,
                                size: 18,
                                color: Color(0x80FFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeHeader extends StatefulWidget {
  const _DateTimeHeader();

  @override
  State<_DateTimeHeader> createState() => _DateTimeHeaderState();
}

class _DateTimeHeaderState extends State<_DateTimeHeader> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      if (now.hour != _now.hour || now.minute != _now.minute) {
        setState(() => _now = now);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.timeLabel(_now),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -1.8,
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_now.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.dateShortLabel(_now),
              style: const TextStyle(
                color: Color(0xC7FFFFFF),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.dropCount,
    required this.status,
    required this.strings,
    required this.onTap,
  });

  final int dropCount;
  final ConnectionStatus status;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final online = status is ConnectionConnected;
    final label = dropCount > 0
        ? strings.dropShelfFiles(dropCount)
        : (online ? strings.connectionOnline : strings.connectionOffline);

    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  dropCount > 0 ? LucideIcons.folderClosed : LucideIcons.wifi,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Color(0xBFFFFFFF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _ServiceLink {
  const _ServiceLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.service, required this.onTap});

  final _ServiceLink service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, size: 15, color: AppColors.ink),
              ),
              const SizedBox(width: 9),
              Text(
                service.label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PcInfoCard extends StatelessWidget {
  const _PcInfoCard({required this.session});

  final SavedSession session;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              LucideIcons.laptop,
              size: 21,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.connectedTo(session.pcName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.host}:${session.port}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              'v${session.apiVersion}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
