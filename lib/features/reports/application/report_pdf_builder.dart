import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/resources/app_copy.dart';

class ReportPdfBuilder {
  static Future<Uint8List> buildSummaryBytes({
    required AppCopy copy,
    required DateTime from,
    required DateTime to,
    required double totalSales,
    required double totalExpenses,
    required double net,
    required String currencyCode,
  }) async {
    final doc = pw.Document();
    final df = DateFormat.yMMMd();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(copy.reportsPageTitle, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('${copy.reportRangeLabel} ${df.format(from)} - ${df.format(to)}'),
            pw.SizedBox(height: 16),
            pw.Text('${copy.totalSales}: ${_money(totalSales, currencyCode)}'),
            pw.Text('${copy.totalExpenses}: ${_money(totalExpenses, currencyCode)}'),
            pw.Text('${copy.netProfit}: ${_money(net, currencyCode)}'),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static String _money(double v, String code) {
    return '$code ${v.toStringAsFixed(2)}';
  }
}
