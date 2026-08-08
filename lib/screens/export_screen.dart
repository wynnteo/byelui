import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';

enum _ExportRange { thisMonth, thisYear, allTime, custom }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _dataService = DataService();
  TransactionScope? _scopeFilter;
  _ExportRange _range = _ExportRange.thisMonth;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _exporting = false;

  ({DateTime? from, DateTime? to}) get _resolvedRange {
    final now = DateTime.now();
    switch (_range) {
      case _ExportRange.thisMonth:
        return (from: DateTime(now.year, now.month, 1), to: DateTime(now.year, now.month + 1, 0, 23, 59, 59));
      case _ExportRange.thisYear:
        return (from: DateTime(now.year, 1, 1), to: DateTime(now.year, 12, 31, 23, 59, 59));
      case _ExportRange.allTime:
        return (from: null, to: null);
      case _ExportRange.custom:
        return (from: _customFrom, to: _customTo);
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _customFrom != null && _customTo != null ? DateTimeRange(start: _customFrom!, end: _customTo!) : null,
    );
    if (picked != null) {
      setState(() {
        _customFrom = picked.start;
        _customTo = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _range = _ExportRange.custom;
      });
    }
  }

  Future<void> _export(bool asPdf) async {
    setState(() => _exporting = true);
    try {
      final range = _resolvedRange;
      final transactions = _dataService.getTransactions(scope: _scopeFilter, from: range.from, to: range.to);
      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transactions in that range')));
        }
        return;
      }
      final path = asPdf ? await ExportService.exportPdf(transactions) : await ExportService.exportCsv(transactions);
      await ExportService.share(path, text: 'ByeLui transactions export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('Export transactions', style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 16),

              Text('Who', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              ScopeToggle(value: _scopeFilter, onChanged: (v) => setState(() => _scopeFilter = v)),
              const SizedBox(height: 20),

              Text('Range', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _rangeChip('This month', _ExportRange.thisMonth),
                  _rangeChip('This year', _ExportRange.thisYear),
                  _rangeChip('All time', _ExportRange.allTime),
                  GestureDetector(
                    onTap: _pickCustomRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _range == _ExportRange.custom ? AppTheme.primaryCoral : AppTheme.glassBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _range == _ExportRange.custom ? AppTheme.primaryCoral : AppTheme.glassBorder),
                      ),
                      child: Text(
                        _range == _ExportRange.custom && _customFrom != null
                            ? 'Custom ✓'
                            : 'Custom range',
                        style: AppTheme.bodySmall.copyWith(
                          color: _range == _ExportRange.custom ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              GlassCard(
                child: Text(
                  'Exports include date, type, scope, category, description, '
                  'amount + currency, tags, payment method, and note for each '
                  'transaction — ready to open in Excel/Sheets or attach to an email.',
                  style: AppTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(16)),
                  child: ElevatedButton.icon(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: _exporting ? null : () => _export(false),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Export as CSV'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.glassBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _exporting ? null : () => _export(true),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export as PDF'),
                ),
              ),
              if (_exporting) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangeChip(String label, _ExportRange range) {
    final selected = _range == range;
    return GestureDetector(
      onTap: () => setState(() => _range = range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryCoral : AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryCoral : AppTheme.glassBorder),
        ),
        child: Text(label, style: AppTheme.bodySmall.copyWith(color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}
