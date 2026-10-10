import 'package:flutter/material.dart';

/// Compact minus/value/plus control. Minus is disabled at zero.
class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove),
            onPressed: value <= 0 ? null : onDecrement,
            tooltip: 'Decrease',
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add),
            onPressed: onIncrement,
            tooltip: 'Increase',
          ),
        ],
      ),
    );
  }
}
