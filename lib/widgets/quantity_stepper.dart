import 'package:flutter/material.dart';

/// A compact "[-] value [+]" control for adjusting a quantity.
///
/// Used both inline on the pantry cards and on the detail screen. The minus
/// button disables itself at [min] so the user can't go below zero.
class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityStepper({
    super.key,
    required this.value,
    this.min = 0,
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
            onPressed: value <= min ? null : onDecrement,
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
