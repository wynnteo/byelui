import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class ScopeToggle extends StatelessWidget {
  final TransactionScope? value; // null = "All"
  final ValueChanged<TransactionScope?> onChanged;
  final bool includeAllOption;

  const ScopeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.includeAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final options = <_ScopeOption>[
      if (includeAllOption) const _ScopeOption(null, 'All'),
      const _ScopeOption(TransactionScope.personal, 'Personal'),
      const _ScopeOption(TransactionScope.family, 'Family'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option.scope == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.scope),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryCoral : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label,
                  style: AppTheme.bodyMedium.copyWith(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ScopeOption {
  final TransactionScope? scope;
  final String label;
  const _ScopeOption(this.scope, this.label);
}
