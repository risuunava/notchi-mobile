import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import 'manual_connect_screen.dart';
import 'scan_screen.dart';

class ConnectFirstCard extends StatelessWidget {
  const ConnectFirstCard({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.soft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.qrCode,
              size: 28,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.connectFirstTitle,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            strings.connectFirstBody,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
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
        ],
      ),
    );
  }
}
