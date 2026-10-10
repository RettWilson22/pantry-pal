import 'package:flutter/material.dart';

import '../models/item_category.dart';

/// Category chips for the list. "All" clears the filter.
class CategoryFilter extends StatelessWidget {
  final ItemCategory? selected;
  final ValueChanged<ItemCategory?> onChanged;

  const CategoryFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            context,
            label: 'All',
            icon: Icons.apps,
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final category in ItemCategory.values)
            _chip(
              context,
              label: category.label,
              icon: category.icon,
              color: category.color,
              isSelected: selected == category,
              onTap: () => onChanged(category),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? scheme.onPrimary : accent,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: accent,
        backgroundColor: scheme.surface,
        showCheckmark: false,
      ),
    );
  }
}
