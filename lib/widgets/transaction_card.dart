import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

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
                Row(
                  children: [
                    Text(
                      category?.name ?? 'Other',
                      style: AppTheme.bodySmall,
                    ),
                    Text(' · ', style: AppTheme.bodySmall),
                    Text(DateFormat('d MMM').format(transaction.date), style: AppTheme.bodySmall),
                    if (transaction.scope == TransactionScope.family) ...[
                      Text(' · ', style: AppTheme.bodySmall),
                      Text('Family', style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber)),
                    ],
                    if (transaction.hasPhoto) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.photo_camera, size: 12, color: AppTheme.textTertiary),
                    ],
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
                        child: Text(
                          tag,
                          style: AppTheme.caption.copyWith(color: AppTheme.primaryCoral, fontSize: 10),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                style: AppTheme.bodyLarge.copyWith(color: amountColor, fontWeight: FontWeight.w600),
              ),
            ],
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
