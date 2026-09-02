import 'package:flutter/material.dart';

class PropertyTypeSelector extends StatelessWidget {
  const PropertyTypeSelector({this.onSelected, super.key});

  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    const types = <String>[
      'House',
      'Apartment',
      'Shop',
      'Office',
      'Warehouse',
      'Land',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in types)
          ActionChip(
            label: Text(type),
            onPressed: () => onSelected?.call(type),
          ),
      ],
    );
  }
}
