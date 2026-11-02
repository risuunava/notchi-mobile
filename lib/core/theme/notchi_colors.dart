import 'package:flutter/material.dart';

/// Centralized color palette derived from the Notchi desktop WPF project.
///
/// The obsidian-glass dark tones come from `MainWindow.xaml` (NotchBaseBrush),
/// and the accent blues from both the desktop media-progress gradient and the
/// mobile seed color.
abstract final class NotchiColors {
  // ─── Primary accent gradient ───────────────────────────────────────
  static const gradientStart = Color(0xFF1E2A78);
  static const gradientEnd = Color(0xFF3A4ED8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E2A78), Color(0xFF2D3FAA), Color(0xFF3A4ED8)],
  );

  // ─── Service tile accent colors ────────────────────────────────────
  static const serviceIssue = Color(0xFFE05B5B);
  static const serviceSource = Color(0xFF5B6BE0);
  static const serviceWindows = Color(0xFF2EA37D);
  static const serviceMobile = Color(0xFFD38B2E);

  // ─── Status colors ─────────────────────────────────────────────────
  static const online = Color(0xFF2ECC71);
  static const connecting = Color(0xFFF1C40F);

  // ─── Media progress (from desktop) ─────────────────────────────────
  static const mediaProgressStart = Color(0xFF8FD3FF);
  static const mediaProgressEnd = Color(0xFF1D4ED8);
}
