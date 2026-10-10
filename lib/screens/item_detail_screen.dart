import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../widgets/quantity_stepper.dart';
import 'item_form_screen.dart';

/// Looks the item up by id on every build so edits show up live, and pops
/// itself once the item is deleted.
class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final item = provider.itemById(itemId);

    if (item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItemFormScreen(existing: item),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: item.category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.category.icon,
                    color: item.category.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(item.category.label,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (item.isLowStock) ...[
            _StatusBanner(
              out: item.isOutOfStock,
              onRestock: () => _restock(context, item),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('On hand',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${item.quantity} ${item.unit}',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  QuantityStepper(
                    value: item.quantity,
                    onIncrement: () =>
                        provider.adjustQuantity(item.id, 1),
                    onDecrement: () =>
                        provider.adjustQuantity(item.id, -1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _InfoTile(
            icon: Icons.warning_amber_outlined,
            label: 'Low-stock alert at',
            value: '${item.lowStockThreshold} ${item.unit}',
          ),
          if (item.barcode != null)
            _InfoTile(
              icon: Icons.qr_code_2,
              label: 'Barcode',
              value: item.barcode!,
            ),
          if (item.note != null && item.note!.isNotEmpty)
            _InfoTile(
              icon: Icons.sticky_note_2_outlined,
              label: 'Note',
              value: item.note!,
            ),
          _InfoTile(
            icon: Icons.event_outlined,
            label: 'Added',
            value: _formatDate(item.addedAt),
          ),
          _InfoTile(
            icon: Icons.update_outlined,
            label: 'Last updated',
            value: _formatDate(item.updatedAt),
          ),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, item),
            icon: Icon(Icons.delete_outline, color: scheme.error),
            label: Text('Delete item',
                style: TextStyle(color: scheme.error)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: scheme.error.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restock(BuildContext context, PantryItem item) async {
    // One above the threshold is the smallest amount that clears "low".
    final target = item.lowStockThreshold + 1;
    final delta = target - item.quantity;
    if (delta > 0) {
      await context.read<PantryProvider>().adjustQuantity(item.id, delta);
    }
  }

  Future<void> _confirmDelete(BuildContext context, PantryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('"${item.name}" will be removed from your pantry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<PantryProvider>().deleteItem(item.id);
      // build() pops the screen once the item is gone.
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatusBanner extends StatelessWidget {
  final bool out;
  final VoidCallback onRestock;

  const _StatusBanner({required this.out, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              out ? 'Out of stock' : 'Running low',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRestock,
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
