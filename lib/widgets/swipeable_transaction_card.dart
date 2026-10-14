import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/data_service.dart';
import '../services/photo_service.dart';
import '../theme/app_theme.dart';
import 'transaction_card.dart';
import '../i18n/s.dart';

/// Wraps TransactionCard with swipe gestures:
/// - swipe right → opens edit (card springs back, doesn't actually dismiss)
/// - swipe left → delete, with confirmation
class SwipeableTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const SwipeableTransactionCard({
    super.key,
    required this.transaction,
    required this.category,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.accentAmber.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.edit, color: AppTheme.accentAmber),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: AppTheme.errorColor),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onTap();
          return false;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.primaryCharcoal,
            title: Text(S.t.deleteTransactionQ, style: AppTheme.headingSmall),
            content: Text(S.t.cantBeUndone, style: AppTheme.bodyMedium),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.t.cancel)),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(S.t.delete, style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        );
        return confirmed == true;
      },
      onDismissed: (_) async {
        await PhotoService.deletePhoto(transaction.photoPath);
        await DataService().deleteTransaction(transaction.id);
        onChanged();
      },
      child: TransactionCard(transaction: transaction, category: category, onTap: onTap),
    );
  }
}
