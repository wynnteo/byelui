import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import '../i18n/s.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final amountColor = isExpense ? AppTheme.textPrimary : AppTheme.successColor;
    final sign = isExpense ? '-' : '+';
    final catColor = category?.color ?? AppTheme.otherColor;

    // Short "paid with" indicator: a named card's first word (e.g. "Mari CC"
    // -> "Mari") so it reads at a glance, or the generic method label.
    String? paymentLabel;
    Color? paymentColor;
    if (transaction.paymentCardId != null) {
      final card = DataService().getPaymentCardById(transaction.paymentCardId!);
      if (card != null) {
        paymentLabel = card.name.trim().split(RegExp(r'\s+')).first;
        paymentColor = card.color;
      }
    } else if (transaction.paymentMethod != null) {
      paymentLabel = DataService().paymentMethodLabel(transaction.paymentMethod!);
    }

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(category?.icon ?? Icons.label, color: catColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Metadata can be wider than a narrow phone, especially with
                // long categories, payment labels and the Family indicator.
                // Wrap onto a new line instead of overflowing the Row.
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(category?.displayName ?? S.t.other, style: AppTheme.bodySmall),
                    Text('·', style: AppTheme.bodySmall),
                    Text(S.dayMonth(transaction.date), style: AppTheme.bodySmall),
                    if (paymentLabel != null) ...[
                      Text('·', style: AppTheme.bodySmall),
                      Icon(Icons.credit_card, size: 11, color: paymentColor ?? AppTheme.textTertiary),
                      Text(
                        paymentLabel,
                        style: AppTheme.bodySmall.copyWith(color: paymentColor ?? AppTheme.textSecondary),
                      ),
                    ],
                    if (transaction.scope == TransactionScope.family) ...[
                      Text('·', style: AppTheme.bodySmall),
                      Text(S.t.family, style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber)),
                    ],
                    if (transaction.hasPhoto)
                      Icon(Icons.photo_camera, size: 12, color: AppTheme.textTertiary),
                  ],
                ),
                if (transaction.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: transaction.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCoral.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.42,
                          ),
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.caption.copyWith(color: AppTheme.stampText, fontSize: 10),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.38,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '$sign${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                maxLines: 1,
                style: AppTheme.bodyLarge.copyWith(color: amountColor, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (transaction.hasPhoto) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(transaction.photoPath!),
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 32, height: 32),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
