import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/resources/app_copy.dart';

class ReportPdfBuilder {
  static const PdfColor _ink = PdfColors.black;
  static const PdfColor _ruleColor = PdfColor.fromInt(0xFF333333);

  static final PdfPageFormat _thermalMultiPage = PdfPageFormat.roll80.copyWith(
    height: 297 * PdfPageFormat.mm,
  );

  static pw.TextStyle _style({
    double size = 9,
    pw.FontWeight weight = pw.FontWeight.normal,
  }) =>
      pw.TextStyle(fontSize: size, fontWeight: weight, color: _ink);

  static pw.Widget _dividerBar() => pw.Center(
        child: pw.Container(
          width: 48,
          height: 0.6,
          color: _ruleColor,
        ),
      );

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

  static pw.Widget _moneyRow(String label, String moneyLine) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: _style(size: 9, weight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
              moneyLine,
              style: _style(size: 9, weight: pw.FontWeight.bold),
            ),
          ],
        ),
      );

  static Future<Uint8List> buildSummaryBytes({
    required AppCopy copy,
    required DateTime from,
    required DateTime to,
    required String periodLabel,
    required int saleCount,
    required int expenseCount,
    required double totalSales,
    required double totalExpenses,
    required double net,
    required String currencyCode,
  }) async {
    final doc = pw.Document(compress: false);
    final dfShort = DateFormat('MMM d, yyyy · h:mm a');

    doc.addPage(
      pw.MultiPage(
        pageFormat: _thermalMultiPage,
        build: (context) => [
          pw.Text(
            copy.reportsPageTitle.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: _style(size: 11, weight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            copy.reportExportSubtitle,
            textAlign: pw.TextAlign.center,
            style: _style(size: 8, weight: pw.FontWeight.normal),
          ),
          pw.SizedBox(height: 6),
          _dividerBar(),
          pw.SizedBox(height: 6),
          _metaRow(copy.reportExportPeriodLabel, periodLabel),
          _metaRow(
            copy.reportRangeLabel.replaceAll(':', ''),
            '${dfShort.format(from)} – ${dfShort.format(to)}',
          ),
          _metaRow(
            copy.reportExportRecordsLabel,
            copy.reportExportRecordsValue(saleCount, expenseCount),
          ),
          _rule(),
          _moneyRow(copy.totalSales, _money(totalSales, currencyCode)),
          _moneyRow(copy.totalExpenses, _money(totalExpenses, currencyCode)),
          _rule(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                copy.netProfit.toUpperCase(),
                style: _style(size: 10, weight: pw.FontWeight.bold),
              ),
              pw.Text(
                _money(net, currencyCode),
                style: _style(size: 12, weight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            copy.isEnglish ? 'Thank you.' : 'Salamat po.',
            textAlign: pw.TextAlign.center,
            style: _style(size: 8, weight: pw.FontWeight.normal),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _money(double v, String code) {
    return '$code ${v.toStringAsFixed(2)}';
  }
}
