import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/credit_card_statement.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';

class CreditCardBillsScreen extends StatefulWidget {
  final TransactionScope? initialScope;
  const CreditCardBillsScreen({super.key, this.initialScope});

  @override
  State<CreditCardBillsScreen> createState() => _CreditCardBillsScreenState();
}

class _CreditCardBillsScreenState extends State<CreditCardBillsScreen> {
  final _data = DataService();
  TransactionScope? _scope;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
  }

  Future<void> _edit([CreditCardStatement? existing]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreditCardBillEditor(
        existing: existing,
        initialScope: _scope ?? TransactionScope.personal,
      )),
    );
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _toggle(CreditCardStatement statement) async {
    await _data.saveCardStatement(statement.copyWith(
      paid: !statement.isPaid,
      paidAt: statement.isPaid ? null : DateTime.now(),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _remove(CreditCardStatement statement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card statement?'),
        content: const Text('This only removes the reminder. No expense transactions are affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _data.deleteCardStatement(statement.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final all = _data.getCardStatements()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final items = _scope == null ? all : all.where((x) => x.scope == _scope).toList();
    final unpaid = items.where((x) => !x.isPaid).length;
    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      appBar: AppBar(
        title: const Text('Credit card bills'),
        backgroundColor: AppTheme.primaryCharcoal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          ScopeToggle(value: _scope, onChanged: (v) => setState(() => _scope = v)),
          const SizedBox(height: 12),
          Text('$unpaid unpaid statement${unpaid == 1 ? '' : 's'}', style: AppTheme.headingSmall),
          const SizedBox(height: 6),
          Text(
            'Statement payments are reminders only. Marking paid does not add another expense.',
            style: AppTheme.caption,
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            GlassCard(child: Text('No credit card statements. Tap + to add one.', style: AppTheme.bodyMedium)),
          ...items.map((s) {
            final date = s.dueDate;
            final dueText = '${date.day}/${date.month}/${date.year}';
            final status = s.isPaid ? 'Paid' : s.isOverdue ? 'Overdue' : 'Unpaid';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                onTap: () => _edit(s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.credit_card, color: AppTheme.accentAmber),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.cardName, style: AppTheme.headingSmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      Text(status, style: AppTheme.bodySmall.copyWith(color: s.isPaid ? AppTheme.successColor : s.isOverdue ? AppTheme.errorColor : AppTheme.accentAmber)),
                    ]),
                    const SizedBox(height: 8),
                    Text('${s.currency} ${s.statementAmount.toStringAsFixed(2)}', style: AppTheme.numeral(size: 22)),
                    Text('Minimum: ${s.currency} ${s.minimumPayment.toStringAsFixed(2)}', style: AppTheme.bodySmall),
                    Text('Due $dueText · ${s.scope == TransactionScope.family ? 'Family' : 'Personal'}', style: AppTheme.caption),
                    if (s.note != null && s.note!.isNotEmpty)
                      Text(s.note!, style: AppTheme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      TextButton.icon(
                        onPressed: () => _toggle(s),
                        icon: Icon(s.isPaid ? Icons.undo : Icons.check_circle_outline),
                        label: Text(s.isPaid ? 'Mark unpaid' : 'Mark paid'),
                      ),
                      TextButton.icon(
                        onPressed: () => _remove(s),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ]),
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

class CreditCardBillEditor extends StatefulWidget {
  final CreditCardStatement? existing;
  final TransactionScope initialScope;
  const CreditCardBillEditor({super.key, this.existing, required this.initialScope});

  @override
  State<CreditCardBillEditor> createState() => _CreditCardBillEditorState();
}

class _CreditCardBillEditorState extends State<CreditCardBillEditor> {
  final _data = DataService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _minimum;
  late final TextEditingController _note;
  late TransactionScope _scope;
  late DateTime _dueDate;
  late String _currency;
  String? _cardId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.cardName ?? '');
    _amount = TextEditingController(text: s?.statementAmount.toStringAsFixed(2) ?? '');
    _minimum = TextEditingController(text: s?.minimumPayment.toStringAsFixed(2) ?? '0');
    _note = TextEditingController(text: s?.note ?? '');
    _scope = s?.scope ?? widget.initialScope;
    _dueDate = s?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _currency = s?.currency ?? _data.baseCurrency;
    _cardId = s?.paymentCardId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _minimum.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final amount = double.parse(_amount.text.trim());
    final minimum = double.parse(_minimum.text.trim());
    if (!amount.isFinite || !minimum.isFinite || amount < 0 || minimum < 0 || minimum > amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Minimum payment must be between 0 and the statement amount.'),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final old = widget.existing;
      await _data.saveCardStatement(CreditCardStatement(
        id: old?.id ?? CreditCardStatement.create(
          cardName: _name.text.trim(), scope: _scope, currency: _currency,
          statementAmount: amount, minimumPayment: minimum, dueDate: _dueDate,
        ).id,
        cardName: _name.text.trim(),
        paymentCardId: _cardId,
        scope: _scope,
        currency: _currency,
        statementAmount: amount,
        minimumPayment: minimum,
        dueDate: _dueDate,
        paidAt: old?.paidAt,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save statement: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _data.getPaymentCards();
    final selected = cards.any((c) => c.id == _cardId) ? _cardId : null;
    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      appBar: AppBar(title: Text(widget.existing == null ? 'Add card statement' : 'Edit card statement'),
        backgroundColor: AppTheme.primaryCharcoal),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ScopeToggle(value: _scope, includeAllOption: false,
              onChanged: (v) { if (v != null) setState(() => _scope = v); }),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selected,
              isExpanded: true,
              dropdownColor: AppTheme.primaryCharcoal,
              decoration: const InputDecoration(labelText: 'Saved payment card (optional)'),
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('Other / enter card name')),
                ...cards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) {
                setState(() {
                  _cardId = v == '' ? null : v;
                  final card = cards.where((c) => c.id == v).firstOrNull;
                  if (card != null) _name.text = card.name;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Card / bank name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a card name' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currency, dropdownColor: AppTheme.primaryCharcoal,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: ['SGD', 'MYR', 'USD'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Statement amount'),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                return n == null || !n.isFinite || n < 0 ? 'Enter a valid statement amount' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minimum, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Minimum payment'),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                return n == null || !n.isFinite || n < 0 ? 'Enter a valid minimum payment' : null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Payment due date'),
              subtitle: Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _dueDate,
                  firstDate: DateTime(2020), lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            TextFormField(controller: _note, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Note (optional)')),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save statement')),
          ],
        ),
      ),
    );
  }
}
