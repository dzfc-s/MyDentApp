import 'package:flutter/material.dart';

import '../models/enums.dart';

/// MyDent brand palette (purple/violet), matching the approved Figma design.
/// Desktop = light theme: pale lavender surfaces, dark-purple sidebar (wired in
/// layouts/master_screen.dart, not here, since Drawer color isn't part of ThemeData).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF7C3AED);
  static const primaryDark = Color(0xFF180B2E);
  static const surfaceLight = Color(0xFFF6F4FB);

  static const success = Color(0xFF16A34A);
  static const successContainer = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerContainer = Color(0xFFFEE2E2);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surfaceLight,
    cardTheme: CardThemeData(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(color: Colors.black87),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
      dataRowMinHeight: 56,
      dataRowMaxHeight: 64,
    ),
  );
}

/// Rounded pill status badge matching the design's colored status chips
/// (green=Potvrđeno/Aktivan, amber=Čeka, red=Otkazano, purple=Završeno).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  factory StatusBadge.appointment(AppointmentStatus status) {
    final (color, bg) = switch (status) {
      AppointmentStatus.pending => (AppColors.warning, AppColors.warningContainer),
      AppointmentStatus.confirmed => (AppColors.success, AppColors.successContainer),
      AppointmentStatus.cancelled => (AppColors.danger, AppColors.dangerContainer),
      AppointmentStatus.completed => (AppColors.primary, const Color(0xFFEDE4FC)),
    };
    return StatusBadge(label: status.label, color: color, background: bg);
  }

  factory StatusBadge.payment(PaymentStatus status) {
    final (color, bg) = switch (status) {
      PaymentStatus.pending => (AppColors.warning, AppColors.warningContainer),
      PaymentStatus.paid => (AppColors.success, AppColors.successContainer),
      PaymentStatus.failed => (AppColors.danger, AppColors.dangerContainer),
      PaymentStatus.refunded => (AppColors.primary, const Color(0xFFEDE4FC)),
    };
    return StatusBadge(label: status.label, color: color, background: bg);
  }

  /// Generic Aktivna/Neaktivna pill — Figma shows entity active state as a
  /// colored pill rather than a plain "Da/Ne" text cell (used by the
  /// services table so far; any other list can reuse it the same way).
  factory StatusBadge.active(bool isActive) {
    return StatusBadge(
      label: isActive ? 'Aktivna' : 'Neaktivna',
      color: isActive ? AppColors.success : AppColors.danger,
      background: isActive ? AppColors.successContainer : AppColors.dangerContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
