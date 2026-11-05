import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../shelf/model/shelf_item.dart';
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

// ---------------------------------------------------------------------------
// Not paired view
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Connected home
// ---------------------------------------------------------------------------

class _ConnectedHome extends ConsumerStatefulWidget {
  const _ConnectedHome({required this.session});

  final SavedSession session;

  @override
  ConsumerState<_ConnectedHome> createState() => _ConnectedHomeState();
}

class _ConnectedHomeState extends ConsumerState<_ConnectedHome> {
  bool _headerCollapsed = false;
  double _dragAccum = 0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragAccum += details.delta.dy;
    // collapse on drag up >= 36px, expand on drag down >= 36px
    if (_dragAccum < -36 && !_headerCollapsed) {
      setState(() => _headerCollapsed = true);
      _dragAccum = 0;
    } else if (_dragAccum > 36 && _headerCollapsed) {
      setState(() => _headerCollapsed = false);
      _dragAccum = 0;
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragAccum = 0;
    final v = details.primaryVelocity ?? 0;
    if (v < -600 && !_headerCollapsed) {
      setState(() => _headerCollapsed = true);
    } else if (v > 600 && _headerCollapsed) {
      setState(() => _headerCollapsed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final status = ref.watch(connectionControllerProvider);
    final history = ref.watch(shelfControllerProvider).history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: _Header(
            session: widget.session,
            status: status,
            history: history,
            collapsed: _headerCollapsed,
            onPillTap: () {
              if (history.isNotEmpty) {
                final isNote = history.first.isText;
                ref.read(shellTabProvider.notifier).select(isNote ? 2 : 1);
              } else {
                ref.read(shellTabProvider.notifier).select(3);
              }
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Calendar
                const _CalendarSection(),
                const SizedBox(height: 8),

                // Services + Windows Information
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle(title: strings.servicesTitle),
                      const SizedBox(height: 14),
                      _buildServicesGrid(context, strings),
                      const SizedBox(height: 30),
                      _SectionTitle(title: strings.windowsInfoTitle),
                      const SizedBox(height: 14),
                      _PcInfoCard(session: widget.session),
                      const SizedBox(height: 12),
                      const SystemStatusCard(),
                      const SizedBox(height: 24),
                      Text(
                        strings.homeSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid(BuildContext context, AppStrings strings) {
    final services = _services(strings);
    return Column(
      children: [
        for (var i = 0; i < services.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ServiceChip(
                  service: services[i],
                  onTap: () => _openLink(context, services[i].url),
                ),
              ),
              const SizedBox(width: 10),
              if (i + 1 < services.length)
                Expanded(
                  child: _ServiceChip(
                    service: services[i + 1],
                    onTap: () => _openLink(context, services[i + 1].url),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ],
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({
    required this.session,
    required this.status,
    required this.history,
    required this.collapsed,
    required this.onPillTap,
  });

  final SavedSession session;
  final ConnectionStatus status;
  final List<ShelfHistoryEntry> history;
  final bool collapsed;
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
      colors: [Color(0xFF000000), Color(0xFF0A1628), Color(0xFF0D2144)],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final media = ref.watch(mediaControllerProvider);
    final artBytes = ref.watch(mediaArtProvider);
    final sourceApp = media?.sourceApp;
    final hasMedia = media != null && media.available;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(gradient: _headerGradient(sourceApp)),
            child: Stack(
              children: [
                // Album art background (low opacity) — hanya di expanded
                if (hasMedia && artBytes != null && !collapsed)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.memory(
                        artBytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                // Glow effects
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

                // Content
                AnimatedPadding(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  padding: collapsed
                      ? const EdgeInsets.fromLTRB(18, 14, 18, 14)
                      : const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting + PC name + status pill — tersembunyi saat collapsed
                      AnimatedSize(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: collapsed
                            ? const SizedBox.shrink()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Greeting / Enjoy label
                                  AnimatedOpacity(
                                    opacity: collapsed ? 0 : 1,
                                    duration: const Duration(milliseconds: 220),
                                    child: Text(
                                      hasMedia
                                          ? strings.enjoyYourApp
                                          : strings.greetingByTime(
                                              DateTime.now().hour),
                                      style: const TextStyle(
                                        color: Color(0xBFFFFFFF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // PC name
                                  AnimatedOpacity(
                                    opacity: collapsed ? 0 : 1,
                                    duration: const Duration(milliseconds: 220),
                                    child: Text(
                                      session.pcName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.0,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Status pill
                                  AnimatedOpacity(
                                    opacity: collapsed ? 0 : 1,
                                    duration: const Duration(milliseconds: 220),
                                    child: _StatusPill(
                                      history: history,
                                      status: status,
                                      strings: strings,
                                      onTap: onPillTap,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ),
                      ),

                      // Media player — selalu tampil
                      const MediaPlayerCard(),
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


// ---------------------------------------------------------------------------
// Glow decoration
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Status pill
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.history,
    required this.status,
    required this.strings,
    required this.onTap,
  });

  final List<ShelfHistoryEntry> history;
  final ConnectionStatus status;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData pillIcon;

    if (history.isNotEmpty) {
      final latest = history.first;
      if (latest.isText) {
        final count = history.where((e) => e.isText).length;
        label = strings.dropShelfNotes(count);
        pillIcon = LucideIcons.stickyNote;
      } else {
        final count = history.where((e) => !e.isText).length;
        label = strings.dropShelfFiles(count > 0 ? count : history.length);
        pillIcon = LucideIcons.folderClosed;
      }
    } else if (status is ConnectionConnected) {
      label = strings.connectionOnline;
      pillIcon = LucideIcons.wifi;
    } else if (status is ConnectionReconnecting) {
      label = strings.connectionReconnecting;
      pillIcon = LucideIcons.wifiOff;
    } else {
      label = strings.connectionOffline;
      pillIcon = LucideIcons.wifiOff;
    }

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
                  pillIcon,
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

// ---------------------------------------------------------------------------
// Calendar section
// ---------------------------------------------------------------------------

class _CalendarSection extends StatefulWidget {
  const _CalendarSection();

  @override
  State<_CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<_CalendarSection> {
  bool _isCompact = false;
  late DateTime _displayMonth;
  late DateTime _selectedDate;

  double _dragAccumY = 0;
  bool _dragTriggered = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _selectedDate = now;
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  void _setCompact(bool compact) {
    if (_isCompact == compact) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isCompact = compact;
    });
  }

  void _returnToCurrentPosition() {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    setState(() {
      _isCompact = false;
      _displayMonth = DateTime(now.year, now.month);
      _selectedDate = now;
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragAccumY = 0;
    _dragTriggered = false;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragAccumY += details.primaryDelta ?? 0;

    // Geser ke atas di area kalender -> langsung compact
    if (!_isCompact && _dragAccumY < -20 && !_dragTriggered) {
      _dragTriggered = true;
      _setCompact(true);
    }
    // Geser ke bawah saat compact -> kalender terbuka kembali
    else if (_isCompact && _dragAccumY > 20 && !_dragTriggered) {
      _dragTriggered = true;
      _returnToCurrentPosition();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (!_dragTriggered) {
      if (!_isCompact && v < -200) {
        _setCompact(true);
      } else if (_isCompact && v > 200) {
        _returnToCurrentPosition();
      }
    }
    _dragAccumY = 0;
    _dragTriggered = false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final today = DateTime.now();
    final monthName = strings.monthsFull[_displayMonth.month - 1];
    final year = _displayMonth.year;

    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 240),
        sizeCurve: Curves.easeOutCubic,
        crossFadeState: _isCompact
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        firstChild: _buildCompactView(strings),
        secondChild: _buildFullView(
          strings,
          today,
          monthName,
          year,
          startWeekday,
          daysInMonth,
        ),
      ),
    );
  }

  /// Mode Compact: Menampilkan Hari, Tanggal, Bulan, Tahun (Hitam Putih, Clean & Profesional)
  Widget _buildCompactView(AppStrings strings) {
    final dayName = strings.weekdaysFull[_selectedDate.weekday - 1];
    final monthName = strings.monthsFull[_selectedDate.month - 1];
    final monthShort = strings.monthsShort[_selectedDate.month - 1];
    final day = _selectedDate.day;
    final year = _selectedDate.year;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _returnToCurrentPosition,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                // Date badge hitam putih yang rapi & profesional
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monthShort.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '$day',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Informasi Hari, Tanggal, Bulan, dan Tahun
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hari
                      Text(
                        dayName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Tanggal, Bulan, Tahun
                      Text(
                        '$day $monthName $year',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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

  /// Mode Penuh: Menampilkan grid kalender bulanan lengkap tanpa icon scale
  Widget _buildFullView(
    AppStrings strings,
    DateTime today,
    String monthName,
    int year,
    int startWeekday,
    int daysInMonth,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Month header with navigation (tanpa icon scale)
          Row(
            children: [
              _CalNavButton(
                icon: LucideIcons.chevronLeft,
                onTap: _prevMonth,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _returnToCurrentPosition,
                  child: Text(
                    '$monthName $year',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              _CalNavButton(
                icon: LucideIcons.chevronRight,
                onTap: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day headers
          Row(
            children: [
              for (final day in strings.calendarDaysShort)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Day grid
          _buildGrid(today, startWeekday, daysInMonth),
        ],
      ),
    );
  }

  Widget _buildGrid(DateTime today, int startWeekday, int daysInMonth) {
    final cells = <Widget>[];

    // Empty leading cells
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (int d = 1; d <= daysInMonth; d++) {
      final isToday = today.year == _displayMonth.year &&
          today.month == _displayMonth.month &&
          today.day == d;
      final isSelected = _selectedDate.year == _displayMonth.year &&
          _selectedDate.month == _displayMonth.month &&
          _selectedDate.day == d;

      cells.add(
        _DayCell(
          day: d,
          isToday: isToday,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedDate =
                  DateTime(_displayMonth.year, _displayMonth.month, d);
            });
          },
        ),
      );
    }

    // Build rows of 7
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells = cells.sublist(i, (i + 7).clamp(0, cells.length));
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox.shrink());
      }
      rows.add(
        Row(
          children: rowCells.map((c) => Expanded(child: c)).toList(),
        ),
      );
      if (i + 7 < cells.length) rows.add(const SizedBox(height: 4));
    }

    return Column(children: rows);
  }
}

class _CalNavButton extends StatelessWidget {
  const _CalNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppColors.ink),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    this.isSelected = false,
    this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = isToday
        ? const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          )
        : isSelected
            ? BoxDecoration(
                color: AppColors.soft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 1.5),
              )
            : null;

    final textColor = isToday
        ? Colors.white
        : isSelected
            ? AppColors.ink
            : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: decoration,
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight:
                      isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Service chip
// ---------------------------------------------------------------------------

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
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, size: 14, color: AppColors.ink),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  service.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.arrowUpRight,
                size: 13,
                color: AppColors.muted.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PC Info Card
// ---------------------------------------------------------------------------

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
            child: Text(
              strings.connectedTo(session.pcName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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
