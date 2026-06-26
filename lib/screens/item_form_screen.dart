import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_category.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../services/product_catalog.dart';

/// Add a new item or edit an existing one.
///
/// In add mode it can be seeded with a scanned [barcode]; if that barcode is in
/// the on-device [ProductCatalog] the name and category are pre-filled, but the
/// user always reviews and confirms (and can change anything) before saving —
/// this is the "user input beyond the ML result" step.
class ItemFormScreen extends StatefulWidget {
  /// When non-null we're editing this item; otherwise we're adding.
  final PantryItem? existing;

  /// A scanned barcode to attach to a brand-new item (add mode only).
  final String? barcode;

  const ItemFormScreen({super.key, this.existing, this.barcode});

  bool get isEditing => existing != null;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  late ItemCategory _category;
  late int _quantity;
  late String _unit;
  late int _threshold;

  static const _units = ['pcs', 'pack', 'box', 'bottle', 'can', 'g', 'kg', 'ml', 'L'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    // Seed from the on-device catalog if this is a recognised barcode.
    final match =
        widget.barcode != null ? ProductCatalog.lookup(widget.barcode!) : null;

    _nameController =
        TextEditingController(text: existing?.name ?? match?.name ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _category = existing?.category ?? match?.category ?? ItemCategory.other;
    _quantity = existing?.quantity ?? 1;
    _unit = existing?.unit.isNotEmpty == true ? existing!.unit : 'pcs';
    if (!_units.contains(_unit)) _unit = 'pcs';
    _threshold = existing?.lowStockThreshold ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<PantryProvider>();

    if (widget.isEditing) {
      await provider.updateItem(
        widget.existing!.copyWith(
          name: _nameController.text,
          category: _category,
          quantity: _quantity,
          unit: _unit,
          lowStockThreshold: _threshold,
          note: _noteController.text,
        ),
      );
    } else {
      await provider.addItem(
        name: _nameController.text,
        barcode: widget.barcode,
        category: _category,
        quantity: _quantity,
        unit: _unit,
        lowStockThreshold: _threshold,
        note: _noteController.text,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Item updated' : 'Item added'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final barcode = widget.barcode ?? widget.existing?.barcode;
    final recognised = widget.barcode != null &&
        ProductCatalog.lookup(widget.barcode!) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit item' : 'Add item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (barcode != null && barcode.isNotEmpty)
              _BarcodeBanner(barcode: barcode, recognised: recognised),
            if (barcode != null && barcode.isNotEmpty)
              const SizedBox(height: 16),

            // --- Name (required) ---
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g. Whole milk',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length > 60) {
                  return 'Name is too long';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // --- Category ---
            DropdownButtonFormField<ItemCategory>(
              value: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final c in ItemCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18, color: c.color),
                        const SizedBox(width: 8),
                        Text(c.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? ItemCategory.other),
            ),
            const SizedBox(height: 16),

            // --- Quantity + unit ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _quantityField()),
                const SizedBox(width: 12),
                Expanded(child: _unitField()),
              ],
            ),
            const SizedBox(height: 16),

            // --- Low-stock threshold ---
            _thresholdField(),
            const SizedBox(height: 16),

            // --- Note (optional) ---
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Brand, expiry, where it lives…',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
              ),
            ),
            const SizedBox(height: 8),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(widget.isEditing ? 'Save changes' : 'Add to pantry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityField() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quantity',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantity <= 0
                    ? null
                    : () => setState(() => _quantity--),
              ),
              Text('$_quantity',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _unit,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            for (final u in _units)
              DropdownMenuItem(value: u, child: Text(u)),
          ],
          onChanged: (value) => setState(() => _unit = value ?? 'pcs'),
        ),
      ],
    );
  }

  Widget _thresholdField() {
    return TextFormField(
      initialValue: '$_threshold',
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Low-stock alert at',
        helperText: 'Flag this item as "low" when its quantity drops to here.',
        prefixIcon: Icon(Icons.warning_amber_outlined),
      ),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null) return 'Enter a whole number';
        if (parsed < 0) return 'Cannot be negative';
        if (parsed > 999) return 'Too large';
        return null;
      },
      onChanged: (value) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) _threshold = parsed;
      },
    );
  }
}

/// A small banner confirming which barcode is attached and whether it was
/// recognised in the on-device catalog.
class _BarcodeBanner extends StatelessWidget {
  final String barcode;
  final bool recognised;

  const _BarcodeBanner({required this.barcode, required this.recognised});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanned barcode',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(barcode,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (recognised)
                  Text('Recognised — details pre-filled below',
                      style: TextStyle(
                          fontSize: 12, color: scheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
