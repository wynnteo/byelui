import 'package:flutter/material.dart';
import '../models/payment_card.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../i18n/s.dart';

const List<Color> _cardColorChoices = [
  AppTheme.primaryCoral,
  AppTheme.accentAmber,
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFF64748B),
];

/// Simple management screen for named payment cards (e.g. "Trust Card",
/// "Mari Card") that can be picked on transactions and seen broken down
/// in Analytics. No goals or tracking — just identity.
class PaymentCardsScreen extends StatefulWidget {
  const PaymentCardsScreen({super.key});

  @override
  State<PaymentCardsScreen> createState() => _PaymentCardsScreenState();
}

class _PaymentCardsScreenState extends State<PaymentCardsScreen> {
  final _dataService = DataService();

  Future<void> _openEditor({PaymentCard? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.primaryCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PaymentCardEditorSheet(existing: existing),
    );
    if (result == null) return;

    try {
      if (existing != null) {
        final updated = existing.copyWith(
          name: result['name'],
          iconName: result['iconName'],
          colorValue: result['colorValue'],
        );
        await _dataService.updatePaymentCard(updated);
      } else {
        await _dataService.addPaymentCard(
          name: result['name'],
          iconName: result['iconName'],
          colorValue: result['colorValue'],
        );
      }
      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('Failed to save payment card: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t.couldNotSaveCard(e))),
        );
      }
    }
  }

  Future<void> _manageCard(PaymentCard card) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.primaryCharcoal,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(card.icon, color: card.color),
              title: Text(card.name, style: AppTheme.headingSmall),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
              title: Text(S.t.edit, style: AppTheme.bodyLarge),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: Text(S.t.delete, style: TextStyle(color: AppTheme.errorColor)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      await _openEditor(existing: card);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.primaryCharcoal,
          title: Text(S.t.deleteNamedQ(card.name), style: AppTheme.headingSmall),
          content: Text(
            S.t.deleteCardBody,
            style: AppTheme.bodyMedium,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.t.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.t.delete, style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _dataService.deletePaymentCard(card.id);
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<PaymentCard> cards = [];
    Object? loadError;
    try {
      cards = _dataService.getPaymentCards();
    } catch (e, st) {
      debugPrint('getPaymentCards failed: $e\n$st');
      loadError = e;
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(child: Text(S.t.paymentCards, style: AppTheme.headingMedium)),
                    IconButton(
                      icon: Icon(Icons.add, color: AppTheme.stampText),
                      onPressed: () => _openEditor(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  S.t.cardsHint,
                  style: AppTheme.caption,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SelectableText(
                            S.t.couldNotLoadCards('$loadError'),
                            textAlign: TextAlign.center,
                            style: AppTheme.bodySmall,
                          ),
                        ),
                      )
                    : cards.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.credit_card_outlined, size: 40, color: AppTheme.textTertiary),
                              SizedBox(height: 12),
                              Text(
                                S.t.noPaymentCards,
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final card = cards[i];
                          return GlassCard(
                            onTap: () => _manageCard(card),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: card.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(card.icon, color: card.color, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(card.name, style: AppTheme.bodyLarge)),
                                Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet form for creating/editing a PaymentCard. Returns a result
/// map on save, or null on cancel.
class _PaymentCardEditorSheet extends StatefulWidget {
  final PaymentCard? existing;
  const _PaymentCardEditorSheet({this.existing});

  @override
  State<_PaymentCardEditorSheet> createState() => _PaymentCardEditorSheetState();
}

class _PaymentCardEditorSheetState extends State<_PaymentCardEditorSheet> {
  late final TextEditingController _nameController;
  late String _iconName;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _iconName = e?.iconName ?? PaymentCard.selectableIconNames.first;
    _colorValue = e?.colorValue ?? _cardColorChoices.first.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t.enterCardName)),
      );
      return;
    }
    Navigator.pop(context, {
      'name': name,
      'iconName': _iconName,
      'colorValue': _colorValue,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing != null ? S.t.editPaymentCard : S.t.addPaymentCard, style: AppTheme.headingSmall),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              autofocus: widget.existing == null,
              style: AppTheme.bodyLarge,
              decoration: AppTheme.glassInputDecoration(hintText: S.t.cardNameHint),
            ),
            const SizedBox(height: 16),

            Text(S.t.icon, style: AppTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: PaymentCard.selectableIconNames.map((name) {
                final tmp = PaymentCard(id: '', name: '', iconName: name, colorValue: _colorValue, createdAt: DateTime.now());
                final selected = name == _iconName;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _iconName = name),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected ? Color(_colorValue).withOpacity(0.25) : AppTheme.glassBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? Color(_colorValue) : AppTheme.glassBorder, width: selected ? 2 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Icon(tmp.icon, color: selected ? Color(_colorValue) : AppTheme.textSecondary, size: 18),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text(S.t.color, style: AppTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: _cardColorChoices.map((c) {
                final selected = c.value == _colorValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _colorValue = c.value),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  style: AppTheme.primaryButtonStyle,
                  onPressed: _save,
                  child: Text(S.t.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
