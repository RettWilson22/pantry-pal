import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_category.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../widgets/category_filter.dart';
import '../widgets/empty_state.dart';
import '../widgets/pantry_item_card.dart';
import '../widgets/summary_bar.dart';
import 'item_detail_screen.dart';
import 'item_form_screen.dart';
import 'scan_screen.dart';

/// The dashboard: summary header, search, category filters and the grouped
/// pantry list, plus the scan button that kicks off the whole flow.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Scan → (duplicate check) → add/edit form. Drives the core ML workflow.
  Future<void> _startScanFlow() async {
    final provider = context.read<PantryProvider>();

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );

    if (!mounted || result == null) return; // cancelled

    // Empty string == user chose "enter manually" from the scanner.
    if (result.isEmpty) {
      _openForm();
      return;
    }

    // A real barcode came back — if we already track it, offer to bump the
    // quantity instead of creating a duplicate record.
    final existing = provider.findByBarcode(result);
    if (existing != null) {
      await _handleDuplicate(existing);
    } else {
      _openForm(barcode: result);
    }
  }

  Future<void> _handleDuplicate(PantryItem existing) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Already in your pantry'),
        content: Text(
          '"${existing.name}" is already saved (${existing.quantity} '
          '${existing.unit}). What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('edit'),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('add'),
            child: const Text('Add one'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    switch (choice) {
      case 'add':
        await context.read<PantryProvider>().adjustQuantity(existing.id, 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added one more ${existing.name}')),
          );
        }
        break;
      case 'edit':
        _openDetail(existing.id);
        break;
      default:
        break;
    }
  }

  void _openForm({String? barcode}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(barcode: barcode),
      ),
    );
  }

  void _openDetail(String id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry Pal'),
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScanFlow,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan'),
      ),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SummaryBar(
                      summary: provider.summary,
                      lowStockActive: provider.showLowStockOnly,
                      onTapLowStock: provider.toggleLowStockOnly,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search your pantry',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: provider.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CategoryFilter(
                      selected: provider.categoryFilter,
                      onChanged: provider.setCategoryFilter,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildBody(provider)),
                ],
              ),
      ),
    );
  }

  Widget _buildBody(PantryProvider provider) {
    // First-run / truly empty pantry.
    if (provider.hasNoItems) {
      return EmptyState(
        icon: Icons.kitchen_outlined,
        title: 'Your pantry is empty',
        message:
            'Tap Scan to add your first item by scanning its barcode — or '
            'enter it by hand.',
        action: FilledButton.icon(
          onPressed: _startScanFlow,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan an item'),
        ),
      );
    }

    // Has items, but the active filters/search match nothing.
    final grouped = provider.groupedItems;
    if (grouped.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'No items match your search or filters.',
        action: TextButton.icon(
          onPressed: () {
            _searchController.clear();
            provider.clearFilters();
          },
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Clear filters'),
        ),
      );
    }

    // Render category sections in enum order for a stable layout.
    final categories =
        ItemCategory.values.where(grouped.containsKey).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(
                children: [
                  Icon(category.icon, size: 18, color: category.color),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('(${items.length})',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                ],
              ),
            ),
            for (final item in items) ...[
              PantryItemCard(
                item: item,
                onTap: () => _openDetail(item.id),
                onIncrement: () => provider.adjustQuantity(item.id, 1),
                onDecrement: () => provider.adjustQuantity(item.id, -1),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
