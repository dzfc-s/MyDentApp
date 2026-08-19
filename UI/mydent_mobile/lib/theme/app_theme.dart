import 'package:flutter/material.dart';

import '../models/enums.dart';

/// MyDent brand palette (purple/violet), matching the approved Figma design.
/// Mobile = dark theme: near-black purple background, slightly lighter purple cards.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF8B5CF6);
  static const background = Color(0xFF120821);
  static const surface = Color(0xFF1E1030);

  static const success = Color(0xFF22C55E);
  static const successContainer = Color(0xFF14361F);
  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFF3A2A0C);
  static const danger = Color(0xFFEF4444);
  static const dangerContainer = Color(0xFF3A1414);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primary,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(color: Colors.white70),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
    ),
    cardColor: AppColors.surface,
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
      AppointmentStatus.completed => (AppColors.primary, const Color(0xFF2B1B4A)),
    };
    return StatusBadge(label: status.label, color: color, background: bg);
  }

  factory StatusBadge.payment(PaymentStatus status) {
    final (color, bg) = switch (status) {
      PaymentStatus.pending => (AppColors.warning, AppColors.warningContainer),
      PaymentStatus.paid => (AppColors.success, AppColors.successContainer),
      PaymentStatus.failed => (AppColors.danger, AppColors.dangerContainer),
      PaymentStatus.refunded => (AppColors.primary, const Color(0xFF2B1B4A)),
    };
    return StatusBadge(label: status.label, color: color, background: bg);
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
