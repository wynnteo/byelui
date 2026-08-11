import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _dataService = DataService();
  bool _working = false;

  Future<void> _export() async {
    setState(() => _working = true);
    try {
      final data = _dataService.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${dir.path}/exports');
      if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
      final file = File('${exportsDir.path}/byelui_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], subject: 'ByeLui backup');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup created and shared')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: const Text('Import backup?', style: AppTheme.headingSmall),
        content: Text(
          'This replaces ALL current transactions, categories, recurring '
          "rules, and budgets with what's in the backup file. This can't be undone.",
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await FilePicker.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.isEmpty || result.files.single.path == null) return;

    setState(() => _working = true);
    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      if (!_dataService.isValidBackup(data)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("That doesn't look like a ByeLui backup file")));
        }
        return;
      }

      await _dataService.importAllData(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup imported')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
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
                  Text('Backup & restore', style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Text(
                  'Use this when switching phones. Backup creates a single '
                  'file with all your transactions, categories, recurring '
                  'rules, and budgets — share it to yourself (email, Drive, '
                  "AirDrop, etc), then open it from the new phone's Import.\n\n"
                  "Note: receipt photos aren't included in the backup file "
                  'itself, only the transaction data — photos stay on the '
                  'original device.',
                  style: AppTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(16)),
                  child: ElevatedButton.icon(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: _working ? null : _export,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Create & share backup'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _working ? null : _import,
                  icon: const Icon(Icons.download),
                  label: const Text('Import backup (replaces all data)'),
                ),
              ),
              if (_working) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
