import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/local/app_database.dart';

class ReceiptPdfBuilder {
  static const PdfColor _ink = PdfColors.black;
  static const PdfColor _ruleColor = PdfColor.fromInt(0xFF333333);

  /// Thermal width (80mm); finite height required for [pw.MultiPage].
  static final PdfPageFormat _thermalMultiPage = PdfPageFormat.roll80.copyWith(
    height: 297 * PdfPageFormat.mm,
  );

  static pw.TextStyle _style({
    double size = 9,
    pw.FontWeight weight = pw.FontWeight.normal,
  }) =>
      pw.TextStyle(fontSize: size, fontWeight: weight, color: _ink);

  static pw.Widget _rule() => pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 6),
        height: 0.8,
        color: _ruleColor,
      );

  static pw.Widget _metaRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 72,
              child: pw.Text(
                label,
                style: _style(size: 8, weight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              child: pw.Text(value, style: _style(size: 9)),
            ),
          ],
        ),
      );

  static pw.Widget _tableHeader(
    String cItem,
    String cQty,
    String cUnit,
    String cAmt,
  ) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 4, top: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 0.7, color: _ruleColor),
          ),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                cItem,
                style: _style(size: 7.5, weight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                cQty,
                textAlign: pw.TextAlign.right,
                style: _style(size: 7.5, weight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                cUnit,
                textAlign: pw.TextAlign.right,
                style: _style(size: 7.5, weight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                cAmt,
                textAlign: pw.TextAlign.right,
                style: _style(size: 7.5, weight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  static pw.Widget _tableLine(SaleReceiptLine line, String currencyCode) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(line.productName, style: _style(size: 9, weight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
              child: pw.Text(
                '${line.qty.toStringAsFixed(line.unitType == 'pcs' ? 0 : 2)}\n${line.unitType}',
                textAlign: pw.TextAlign.right,
                style: _style(size: 8.5),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                _money(line.unitPrice, currencyCode),
                textAlign: pw.TextAlign.right,
                style: _style(size: 8.5),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                _money(line.lineTotal, currencyCode),
                textAlign: pw.TextAlign.right,
                style: _style(size: 8.5, weight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  static pw.Widget _tableLineUtang(UtangEntryItemDetail line, String currencyCode) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(line.productName, style: _style(size: 9, weight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
              child: pw.Text(
                '${line.qty.toStringAsFixed(line.unitType == 'pcs' ? 0 : 2)}\n${line.unitType}',
                textAlign: pw.TextAlign.right,
                style: _style(size: 8.5),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                _money(line.unitPrice, currencyCode),
                textAlign: pw.TextAlign.right,
                style: _style(size: 8.5),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                _money(line.lineTotal, currencyCode),
                textAlign: pw.TextAlign.right,
                style: _style(size: 8.5, weight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  static Future<Uint8List> buildSaleReceiptBytes({
    required String title,
    required SaleReceiptDetail receipt,
    required String currencyCode,
    required String labelCustomer,
    required String labelTotal,
    required String labelTransaction,
    required String labelDueDate,
    required String colItem,
    required String colQty,
    required String colUnitPrice,
    required String colLineTotal,
  }) async {
    final doc = pw.Document(compress: false);
    final df = DateFormat('MMM d, yyyy · h:mm a');

    final lineDescriptions = receipt.lines
        .map(
          (line) =>
              '${line.productName} | ${line.qty} ${line.unitType} | ${_money(line.unitPrice, currencyCode)} | ${_money(line.lineTotal, currencyCode)}',
        )
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: _thermalMultiPage,
        build: (context) => [
          pw.Text(
            title.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: _style(size: 11, weight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Container(
              width: 48,
              height: 0.6,
              color: _ruleColor,
            ),
          ),
          pw.SizedBox(height: 6),
          _metaRow(labelCustomer, receipt.customerName),
          _metaRow(labelTransaction.replaceAll(':', ''), df.format(receipt.sale.createdAt)),
          _rule(),
          _tableHeader(colItem, colQty, colUnitPrice, colLineTotal),
          ...receipt.lines.map((l) => _tableLine(l, currencyCode)),
          _rule(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(labelTotal.toUpperCase(), style: _style(size: 10, weight: pw.FontWeight.bold)),
              pw.Text(
                _money(receipt.sale.totalAmount, currencyCode),
                style: _style(size: 12, weight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Thank you.',
            textAlign: pw.TextAlign.center,
            style: _style(size: 8, weight: pw.FontWeight.normal),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final searchableText = [
      title,
      '$labelCustomer: ${receipt.customerName}',
      '$labelTransaction ${df.format(receipt.sale.createdAt)}',
      ...lineDescriptions,
      '$labelTotal: ${_money(receipt.sale.totalAmount, currencyCode)}',
    ].join('\n% ');
    final suffix = '\n% $searchableText\n';

    return Uint8List.fromList(bytes + utf8.encode(suffix));
  }

  static Future<Uint8List> buildUtangReceiptBytes({
    required String title,
    required UtangReceiptDetail receipt,
    required String currencyCode,
    required String labelCustomer,
    required String labelTotal,
    required String labelTransaction,
    required String labelDueDate,
    required String colItem,
    required String colQty,
    required String colUnitPrice,
    required String colLineTotal,
  }) async {
    final doc = pw.Document(compress: false);
    final df = DateFormat('MMM d, yyyy · h:mm a');
    final dueDate = receipt.entry.dueDate;

    final lineDescriptions = receipt.lines
        .map(
          (line) =>
              '${line.productName} | ${line.qty} ${line.unitType} | ${_money(line.unitPrice, currencyCode)} | ${_money(line.lineTotal, currencyCode)}',
        )
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: _thermalMultiPage,
        build: (context) => [
          pw.Text(
            title.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: _style(size: 11, weight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Container(
              width: 48,
              height: 0.6,
              color: _ruleColor,
            ),
          ),
          pw.SizedBox(height: 6),
          _metaRow(labelCustomer, receipt.customerName),
          _metaRow(labelTransaction.replaceAll(':', ''), df.format(receipt.entry.createdAt)),
          if (dueDate != null)
            _metaRow(labelDueDate, DateFormat.yMMMd().format(dueDate)),
          _rule(),
          _tableHeader(colItem, colQty, colUnitPrice, colLineTotal),
          ...receipt.lines.map((l) => _tableLineUtang(l, currencyCode)),
          _rule(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(labelTotal.toUpperCase(), style: _style(size: 10, weight: pw.FontWeight.bold)),
              pw.Text(
                _money(receipt.entry.amount, currencyCode),
                style: _style(size: 12, weight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Thank you.',
            textAlign: pw.TextAlign.center,
            style: _style(size: 8),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final searchableText = [
      title,
      '$labelCustomer: ${receipt.customerName}',
      '$labelTransaction ${df.format(receipt.entry.createdAt)}',
      if (dueDate != null) '$labelDueDate: ${DateFormat.yMMMd().format(dueDate)}',
      ...lineDescriptions,
      '$labelTotal: ${_money(receipt.entry.amount, currencyCode)}',
    ].join('\n% ');
    final suffix = '\n% $searchableText\n';

    return Uint8List.fromList(bytes + utf8.encode(suffix));
  }

  static String _money(double value, String code) {
    return '$code ${value.toStringAsFixed(2)}';
  }
}
