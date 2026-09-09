import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'data_service.dart';

class ExportService {
  static final _dataService = DataService();

  /// Paid By: named card if set, else the generic payment method label, else blank.
  static String _paidByLabel(Transaction t) {
    if (t.paymentCardId != null) {
      final card = _dataService.getPaymentCardById(t.paymentCardId!);
      if (card != null) return card.name;
    }
    if (t.paymentMethod != null) {
      return _dataService.paymentMethodLabel(t.paymentMethod!);
    }
    return '';
  }

  /// Shared row layout for CSV and PDF: Date, Category, Amount, Description,
  /// Paid By, Remarks, Tags, Scope. Amount is signed (negative for expenses,
  /// positive for income) since there's no separate Type column.
  static List<List<String>> _rows(List<Transaction> transactions) {
    final rows = <List<String>>[
      ['Date', 'Category', 'Amount', 'Description', 'Paid By', 'Remarks', 'Tags', 'Scope'],
    ];
    for (final t in transactions) {
      final category = _dataService.getCategoryById(t.categoryId);
      final signedAmount = t.isExpense ? -t.amount : t.amount;
      rows.add([
        DateFormat('yyyy-MM-dd').format(t.date),
        category?.name ?? 'Other',
        signedAmount.toStringAsFixed(2),
        t.description,
        _paidByLabel(t),
        t.note ?? '',
        t.tags.join('; '),
        t.scope == TransactionScope.personal ? 'Personal' : 'Family',
      ]);
    }
    return rows;
  }

  /// Writes a CSV file to the app documents' exports folder and returns its path.
  static Future<String> exportCsv(List<Transaction> transactions, {String? fileNamePrefix}) async {
    final csvString = csv.encode(_rows(transactions));
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
    final fileName = '${fileNamePrefix ?? 'byelui_transactions'}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${exportsDir.path}/$fileName');
    await file.writeAsString(csvString);
    return file.path;
  }

  /// Writes a real .xlsx workbook with columns: Date, Category, Amount,
  /// Description, Paid By, Remarks, Tags, Scope — one row per transaction.
  /// Amount is signed (negative for expenses, positive for income) since
  /// there's no separate Type column here.
  static Future<String> exportXlsx(List<Transaction> transactions, {String? fileNamePrefix}) async {
    final workbook = xlsx.Excel.createExcel();
    const sheetName = 'Transactions';
    final sheet = workbook[sheetName];

    sheet.appendRow([
      xlsx.TextCellValue('Date'),
      xlsx.TextCellValue('Category'),
      xlsx.TextCellValue('Amount'),
      xlsx.TextCellValue('Description'),
      xlsx.TextCellValue('Paid By'),
      xlsx.TextCellValue('Remarks'),
      xlsx.TextCellValue('Tags'),
      xlsx.TextCellValue('Scope'),
    ]);

    for (final t in transactions) {
      final category = _dataService.getCategoryById(t.categoryId);
      final signedAmount = t.isExpense ? -t.amount : t.amount;
      sheet.appendRow([
        xlsx.TextCellValue(DateFormat('yyyy-MM-dd').format(t.date)),
        xlsx.TextCellValue(category?.name ?? 'Other'),
        xlsx.DoubleCellValue(signedAmount),
        xlsx.TextCellValue(t.description),
        xlsx.TextCellValue(_paidByLabel(t)),
        xlsx.TextCellValue(t.note ?? ''),
        xlsx.TextCellValue(t.tags.join('; ')),
        xlsx.TextCellValue(t.scope == TransactionScope.personal ? 'Personal' : 'Family'),
      ]);
    }

    // createExcel() ships with a default empty sheet (usually 'Sheet1') —
    // drop anything that isn't the one we just filled.
    for (final name in workbook.sheets.keys.toList()) {
      if (name != sheetName) workbook.delete(name);
    }

    final bytes = workbook.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');

    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
    final fileName = '${fileNamePrefix ?? 'byelui_transactions'}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final file = File('${exportsDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Writes a simple table PDF to the app documents' exports folder and returns its path.
  static Future<String> exportPdf(
    List<Transaction> transactions, {
    String? fileNamePrefix,
    String title = 'ByeLui transactions',
  }) async {
    final doc = pw.Document();
    final rows = _rows(transactions);
    final base = _dataService.baseCurrency;

    double income = 0, expense = 0;
    for (final t in transactions) {
      final converted = _dataService.convertToBase(t.amount, t.currency);
      if (t.isIncome) {
        income += converted;
      } else {
        expense += converted;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated ${DateFormat('d MMM yyyy, HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text('Income: $base ${income.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(width: 24),
              pw.Text('Expense: $base ${expense.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(width: 24),
              pw.Text('Net: $base ${(income - expense).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: rows.first,
            data: rows.skip(1).toList(),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFF6B4A)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(50),
              3: const pw.FlexColumnWidth(2),
            },
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
    final fileName = '${fileNamePrefix ?? 'byelui_transactions'}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${exportsDir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  static Future<void> share(String filePath, {String? text}) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }
}
