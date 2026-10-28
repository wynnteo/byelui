import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';
import '../i18n/s.dart';
import 'recurring_screen.dart';

typedef UpcomingBill = ({RecurringTransaction rule, DateTime dueDate});

/// Read-only future occurrences. No transaction is created or marked paid.
/// Card statement repayments require a separate reminder model so purchases
/// already recorded as expenses are not counted a second time.
List<UpcomingBill> upcomingRecurringBills(
  List<RecurringTransaction> rules, {
  TransactionScope? scope,
  int days = 30,
  DateTime? today,
}) {
  final start = today ?? DateTime.now();
  final startDay = DateTime(start.year, start.month, start.day);
  final endExclusive = startDay.add(Duration(days: days + 1));
  final result = <UpcomingBill>[];

  for (final rule in rules) {
    if (!rule.isActive || rule.type != TransactionType.expense) continue;
    if (scope != null && rule.scope != scope) continue;
    var due = rule.nextDueDate ?? rule.startDate;
    // A bounded loop guards against invalid or unexpectedly old schedules.
    for (var i = 0; i < 500 && due.isBefore(endExclusive); i++) {
      if (rule.endDate != null && due.isAfter(rule.endDate!)) break;
      if (!due.isBefore(startDay)) {
        result.add((rule: rule, dueDate: due));
      }
      final next = rule.computeNextDate(due);
      if (!next.isAfter(due)) break;
      due = next;
    }
  }
  result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return result;
}

class UpcomingBillsScreen extends StatefulWidget {
  final TransactionScope? initialScope;
  const UpcomingBillsScreen({super.key, this.initialScope});

  @override
  State<UpcomingBillsScreen> createState() => _UpcomingBillsScreenState();
}

class _UpcomingBillsScreenState extends State<UpcomingBillsScreen> {
  final _data = DataService();
  TransactionScope? _scope;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
  }

  @override
  Widget build(BuildContext context) {
    final items = upcomingRecurringBills(
      _data.getRecurringTransactions(activeOnly: true),
      scope: _scope,
    );

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      appBar: AppBar(
        title: Text(S.t.upcomingBills),
        backgroundColor: AppTheme.primaryCharcoal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScopeToggle(value: _scope, onChanged: (value) => setState(() => _scope = value)),
          const SizedBox(height: 16),
          Text(S.t.scheduledExpensesOnly, style: AppTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            S.t.upcomingExplainer,
            style: AppTheme.caption,
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            GlassCard(
              child: Text(
                S.t.noUpcomingRecurring,
                style: AppTheme.bodyMedium,
              ),
            ),
          ...items.map((item) {
            final rule = item.rule;
            final date = item.dueDate;
            final category = _data.getCategoryById(rule.categoryId);
            final formattedDate = S.billingDate(date);
            final card = rule.paymentCardId == null
                ? null
                : _data.getPaymentCardById(rule.paymentCardId!);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecurringFormScreen(existing: rule)),
                  );
                  if (mounted) setState(() {});
                },
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, color: AppTheme.accentAmber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rule.description, style: AppTheme.bodyMedium),
                          Text(
                            '$formattedDate · ${rule.scope == TransactionScope.personal ? S.t.personal : S.t.family}'
                            '${category == null ? '' : ' · ${category.displayName}'}',
                            style: AppTheme.caption,
                          ),
                          if (card != null) Text(card.name, style: AppTheme.caption),
                        ],
                      ),
                    ),
                    Text(
                      '${rule.currency} ${rule.amount.toStringAsFixed(2)}',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
