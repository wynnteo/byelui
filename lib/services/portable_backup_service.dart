import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'data_service.dart';

/// One portable ZIP contains backup.json plus any referenced receipts.
/// Existing 1.0 JSON backups remain supported by BackupScreen.
class PortableBackupService {
  static const int maxArchiveBytes = 120 * 1024 * 1024;
  static const int maxReceiptBytes = 15 * 1024 * 1024;
  static const int maxReceiptCount = 500;
  final DataService data;

  PortableBackupService(this.data);

  Future<File> createZip() async {
    final payload = data.exportAllData();
    final archive = Archive();
    final receipts = <String, String>{};
    final transactions = payload['transactions'] as List;
    var totalBytes = 0;

    for (final raw in transactions) {
      final transaction = raw as Map<String, dynamic>;
      final oldPath = transaction['photoPath'] as String?;
      transaction['photoPath'] = null;
      if (oldPath == null || oldPath.isEmpty) continue;
      final photo = File(oldPath);
      if (!await photo.exists()) continue;
      if (receipts.length >= maxReceiptCount) {
        throw const FormatException('Too many receipt photos for one backup.');
      }
      final bytes = await photo.readAsBytes();
      if (bytes.length > maxReceiptBytes ||
          totalBytes + bytes.length > maxArchiveBytes) {
        throw const FormatException('Receipt backup size limit exceeded.');
      }
      totalBytes += bytes.length;
      final ext = oldPath.split('.').last.toLowerCase();
      final safeExt = {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(ext)
          ? ext : 'jpg';
      final entryName = 'receipts/${const Uuid().v4()}.$safeExt';
      archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
      transaction['photoPath'] = entryName;
      receipts[entryName] = oldPath;
    }

    final jsonBytes = utf8.encode(jsonEncode(payload));
    if (jsonBytes.length + totalBytes > maxArchiveBytes) {
      throw const FormatException('Backup size limit exceeded.');
    }
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) throw const FormatException('Unable to encode backup.');
    final dir = await getApplicationDocumentsDirectory();
    final exports = Directory('${dir.path}/exports');
    await exports.create(recursive: true);
    final output = File(
        '${exports.path}/byelui_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    await output.writeAsBytes(zipped, flush: true);
    return output;
  }

  Future<void> importZip(File input) async {
    if (await input.length() > maxArchiveBytes) {
      throw const FormatException('ZIP backup is too large.');
    }
    final archive = ZipDecoder().decodeBytes(await input.readAsBytes(), verify: true);
    final allFiles = <String, ArchiveFile>{};
    var size = 0;
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      // Prevent directory traversal and ZIP bombs. We never extract paths
      // directly from the archive: generated paths stay inside app documents.
      final name = entry.name;
      if (name != 'backup.json' &&
          !RegExp(r'^receipts/[a-zA-Z0-9_-]+\\.(jpg|jpeg|png|webp|heic)$')
              .hasMatch(name)) {
        throw const FormatException('Invalid ZIP backup entry.');
      }
      if (allFiles.containsKey(name)) {
        throw const FormatException('Duplicate ZIP entry.');
      }
      if (entry.size > maxReceiptBytes && name != 'backup.json') {
        throw const FormatException('Receipt exceeds size limit.');
      }
      size += entry.size;
      if (size > maxArchiveBytes || allFiles.length > maxReceiptCount) {
        throw const FormatException('Backup exceeds size limit.');
      }
      allFiles[name] = entry;
    }
    final jsonFile = allFiles['backup.json'];
    if (jsonFile == null || jsonFile.size > 5 * 1024 * 1024) {
      throw const FormatException('Missing or oversized backup.json.');
    }
    final payload = jsonDecode(utf8.decode(
        List<int>.from(jsonFile.content as List<int>))) as Map<String, dynamic>;
    if (!data.isValidBackup(payload)) {
      throw const FormatException('Invalid ByeLui backup data.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    final created = <File>[];
    final used = <String>{};
    try {
      for (final raw in payload['transactions'] as List) {
        final transaction = raw as Map<String, dynamic>;
        final ref = transaction['photoPath'] as String?;
        if (ref == null) continue;
        if (!ref.startsWith('receipts/') || !allFiles.containsKey(ref)) {
          throw const FormatException('Backup references a missing receipt.');
        }
        if (used.contains(ref)) {
          // Avoid duplicate writes; share the restored photo for duplicates.
          continue;
        }
        used.add(ref);
      }

      final restored = <String, String>{};
      if (used.isNotEmpty) await receiptsDir.create(recursive: true);
      for (final ref in used) {
        final entry = allFiles[ref]!;
        final suffix = ref.split('.').last;
        final destination = File('${receiptsDir.path}/${const Uuid().v4()}.$suffix');
        created.add(destination);
        await destination.writeAsBytes(
            List<int>.from(entry.content as List<int>), flush: true);
        restored[ref] = destination.path;
      }
      for (final raw in payload['transactions'] as List) {
        final transaction = raw as Map<String, dynamic>;
        final ref = transaction['photoPath'] as String?;
        transaction['photoPath'] = ref == null ? null : restored[ref];
      }
      // DB import has its own parse-before-write + rollback. If it fails,
      // remove any extracted photos, leaving the old DB and photos intact.
      await data.importAllData(payload);
    } catch (_) {
      for (final photo in created) {
        if (await photo.exists()) await photo.delete();
      }
      rethrow;
    }
  }
}
