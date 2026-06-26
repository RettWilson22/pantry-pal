import 'package:flutter/material.dart';

import '../providers/pantry_provider.dart';

/// The dashboard header showing three at-a-glance totals: distinct items,
/// total units, and how many items are running low.
///
/// The low-stock tile doubles as a toggle — tapping it filters the list down to
/// just the low items, which is the main "what do I need to buy?" use case.
class SummaryBar extends StatelessWidget {
  final PantrySummary summary;
  final bool lowStockActive;
  final VoidCallback onTapLowStock;

  const SummaryBar({
    super.key,
    required this.summary,
    required this.lowStockActive,
    required this.onTapLowStock,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          icon: Icons.category_outlined,
          value: '${summary.distinctItems}',
          label: 'Items',
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.numbers_outlined,
          value: '${summary.totalUnits}',
          label: 'Total units',
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.warning_amber_outlined,
          value: '${summary.lowStockCount}',
          label: 'Low stock',
          highlight: true,
          active: lowStockActive,
          onTap: onTapLowStock,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;
  final bool active;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = highlight ? scheme.error : scheme.primary;
    final bg = active
        ? accent.withOpacity(0.15)
        : scheme.surface;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? accent : scheme.outlineVariant.withOpacity(0.6),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
