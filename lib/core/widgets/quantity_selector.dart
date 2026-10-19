import 'package:shopsphere/core/localization/app_localization.dart';
import 'package:flutter/material.dart';

/// Stepper that never lets the value leave `[min, max]`.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: context.tr('Decrease quantity'),
          constraints: BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: Semantics(
            label: context.tr('Quantity'),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton.outlined(
          tooltip: context.tr('Increase quantity'),
          constraints: BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
