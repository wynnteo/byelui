import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/data_service.dart';
import '../services/portable_backup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../i18n/s.dart';

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
      final file = await PortableBackupService(_dataService).createZip();
      await Share.shareXFiles([XFile(file.path)], subject: S.t.backupShareSubject);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t.backupCreated)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t.exportFailed(e))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: Text(S.t.importBackupQ, style: AppTheme.headingSmall),
        content: Text(
          S.t.importBackupBody,
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t.importAction, style: TextStyle(color: AppTheme.errorColor)),
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
      if (file.path.toLowerCase().endsWith('.zip')) {
        await PortableBackupService(_dataService).importZip(file);
      } else {
        // Legacy 1.0 JSON backup: photos were not included.
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString) as Map<String, dynamic>;
        if (!_dataService.isValidBackup(data)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.t.notBackupFile)));
          return;
        }
        // Never carry stale absolute paths from the old phone.
        for (final raw in data['transactions'] as List) {
          final transaction = raw as Map<String, dynamic>;
          final path = transaction['photoPath'] as String?;
          if (path != null && !await File(path).exists()) {
            transaction['photoPath'] = null;
          }
        }
        await _dataService.importAllData(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t.backupImported)));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t.importFailed(e))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(S.t.backupRestore, style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Text(
                  S.t.backupInfo,
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
                    label: Text(S.t.createShareBackup),
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
                    side: BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _working ? null : _import,
                  icon: const Icon(Icons.download),
                  label: Text(S.t.importBackupReplaces),
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
