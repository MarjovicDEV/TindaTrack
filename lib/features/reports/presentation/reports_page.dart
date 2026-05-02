import 'dart:ui' as ui;

import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../../shared/widgets/summary_card.dart';
import '../application/report_pdf_builder.dart';
import 'report_export_stub.dart' if (dart.library.io) 'report_export_io.dart' as report_export;

enum ReportFilter { daily, weekly, monthly }

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    required this.repo,
    this.currencyCode = 'PHP',
    super.key,
  });

  final TindaRepository repo;
  final String currencyCode;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportFilter _filter = ReportFilter.daily;
  final GlobalKey _repaintKey = GlobalKey();

  ({DateTime from, DateTime to}) _range() {
    final now = DateTime.now();
    switch (_filter) {
      case ReportFilter.daily:
        return (from: DateTime(now.year, now.month, now.day), to: now);
      case ReportFilter.weekly:
        return (from: now.subtract(const Duration(days: 7)), to: now);
      case ReportFilter.monthly:
        return (from: DateTime(now.year, now.month - 1, now.day), to: now);
    }
  }

  Future<({double totalSales, double totalExpenses, double net})> _totalsForRange() async {
    final range = _range();
    final db = widget.repo.db;
    final sales = await (db.select(db.sales)
          ..where((t) {
            final drift.Expression<DateTime> c = t.createdAt;
            return c.isBetweenValues(range.from, range.to);
          }))
        .get();
    final expenses = await (db.select(db.expenses)
          ..where((t) {
            final drift.Expression<DateTime> c = t.createdAt;
            return c.isBetweenValues(range.from, range.to);
          }))
        .get();
    final totalSales = sales.fold<double>(0, (a, b) => a + b.totalAmount);
    final totalExpenses = expenses.fold<double>(0, (a, b) => a + b.amount);
    return (totalSales: totalSales, totalExpenses: totalExpenses, net: totalSales - totalExpenses);
  }

  Future<void> _exportPng() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ang PNG export ay desktop/mobile app lamang sa ngayon.')),
      );
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Walang ma-export na view.')),
      );
      return;
    }

    try {
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final path = await report_export.writeReportPngBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Na-save ang PNG: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _exportPdf() async {
    try {
      final range = _range();
      final t = await _totalsForRange();
      final bytes = await ReportPdfBuilder.buildSummaryBytes(
        title: AppCopy.reportsPageTitle,
        from: range.from,
        to: range.to,
        totalSales: t.totalSales,
        totalExpenses: t.totalExpenses,
        net: t.net,
        currencyCode: widget.currencyCode,
      );
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF (${bytes.length} bytes) — i-download support sa susunod.')),
        );
        return;
      }
      final path = await report_export.writeReportPdfBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Na-save ang PDF: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range();
    final code = widget.currencyCode;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullW = constraints.maxWidth;
        final gap = AppSpacing.sm;
        return Scrollbar(
          child: SingleChildScrollView(
            primary: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: fullW),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppCopy.reportsPageTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<ReportFilter>(
                      segments: const [
                        ButtonSegment(value: ReportFilter.daily, label: Text(AppCopy.reportFilterDaily)),
                        ButtonSegment(value: ReportFilter.weekly, label: Text(AppCopy.reportFilterWeekly)),
                        ButtonSegment(value: ReportFilter.monthly, label: Text(AppCopy.reportFilterMonthly)),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (value) => setState(() => _filter = value.first),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Saklaw (PH UTC+8): ${formatPhilippineDateTime(range.from)} - ${formatPhilippineDateTime(range.to)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _exportPng,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text(AppCopy.exportPng),
                        ),
                        OutlinedButton.icon(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text(AppCopy.exportPdf),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RepaintBoundary(
                      key: _repaintKey,
                      child: StreamBuilder<List<Sale>>(
                        stream: widget.repo.watchSalesInRange(range.from, range.to),
                        builder: (context, salesSnap) {
                          final sales = salesSnap.data ?? const [];
                          return StreamBuilder<List<Expense>>(
                            stream: widget.repo.watchExpensesInRange(range.from, range.to),
                            builder: (context, expSnap) {
                              final expenses = expSnap.data ?? const [];
                              final totalSales = sales.fold<double>(
                                0,
                                (sum, e) => sum + e.totalAmount,
                              );
                              final totalExpenses = expenses.fold<double>(
                                0,
                                (sum, e) => sum + e.amount,
                              );
                              final net = totalSales - totalExpenses;

                              final spots = <FlSpot>[];
                              for (var i = 0; i < sales.length; i++) {
                                final y = sales[i].totalAmount;
                                spots.add(FlSpot(i.toDouble(), y));
                              }

                              final useTwoCols = fullW >= 320;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (useTwoCols)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: SummaryCard(
                                            label: AppCopy.totalSales,
                                            value: formatCurrency(totalSales, currencyCode: code),
                                            icon: Icons.payments_outlined,
                                          ),
                                        ),
                                        SizedBox(width: gap),
                                        Expanded(
                                          child: SummaryCard(
                                            label: AppCopy.totalExpenses,
                                            value: formatCurrency(totalExpenses, currencyCode: code),
                                            icon: Icons.receipt_outlined,
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    SummaryCard(
                                      label: AppCopy.totalSales,
                                      value: formatCurrency(totalSales, currencyCode: code),
                                      icon: Icons.payments_outlined,
                                    ),
                                    SizedBox(height: gap),
                                    SummaryCard(
                                      label: AppCopy.totalExpenses,
                                      value: formatCurrency(totalExpenses, currencyCode: code),
                                      icon: Icons.receipt_outlined,
                                    ),
                                  ],
                                  SizedBox(height: gap),
                                  SummaryCard(
                                    label: AppCopy.netProfit,
                                    value: formatCurrency(net, currencyCode: code),
                                    icon: Icons.trending_up_outlined,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Card(
                                    child: Padding(
                                      padding: AppSpacing.card,
                                      child: SizedBox(
                                        height: 220,
                                        child: spots.isEmpty
                                            ? const Center(child: Text(AppCopy.noDataRange))
                                            : LineChart(
                                                LineChartData(
                                                  gridData: const FlGridData(show: true),
                                                  titlesData: const FlTitlesData(show: false),
                                                  borderData: FlBorderData(show: false),
                                                  lineBarsData: [
                                                    LineChartBarData(
                                                      isCurved: true,
                                                      spots: spots,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      dotData: const FlDotData(show: false),
                                                      barWidth: 3,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
