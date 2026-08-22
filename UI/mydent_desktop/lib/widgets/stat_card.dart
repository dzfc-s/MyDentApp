import 'package:flutter/material.dart';

/// Small metric summary card used at the top of list screens (e.g. "Total: 12"),
/// and (with [deltaPercent] set) the trend-labeled variant used on the Dashboard.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  /// Percentage change vs. a comparison period, e.g. 12.0 or -5.0.
  /// Null (the default) hides the trend row entirely — existing call sites
  /// that don't pass it keep looking exactly as before.
  final double? deltaPercent;

  /// Trailing text after the delta, e.g. "vs prošli mj." Ignored when
  /// [deltaPercent] is null.
  final String deltaSuffix;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.deltaPercent,
    this.deltaSuffix = 'vs prošli period',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                    if (deltaPercent != null) ...[
                      const SizedBox(height: 4),
                      _DeltaRow(deltaPercent: deltaPercent!, suffix: deltaSuffix),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({required this.deltaPercent, required this.suffix});

  final double deltaPercent;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final positive = deltaPercent >= 0;
    // Green/red are reserved status colors elsewhere in the app (success/danger) —
    // reused here for the same "good vs. bad direction" meaning, always paired
    // with the arrow icon and text so it's never color-alone.
    final statusColor = positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final sign = positive ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(positive ? Icons.trending_up : Icons.trending_down,
            size: 14, color: statusColor),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '$sign${deltaPercent.toStringAsFixed(0)}% $suffix',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
