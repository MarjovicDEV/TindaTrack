import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../backup_restore/application/backup_service.dart';
import '../../../shared/widgets/summary_card.dart';

enum ReportFilter { daily, weekly, monthly }

class ReportsPage extends StatefulWidget {
  const ReportsPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final BackupService _backupService;
  ReportFilter _filter = ReportFilter.daily;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(widget.repo);
  }

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

  @override
  Widget build(BuildContext context) {
    final range = _range();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppCopy.summaryTitle, style: Theme.of(context).textTheme.titleLarge),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Saklaw (PH UTC+8): ${formatPhilippineDateTime(range.from)} - ${formatPhilippineDateTime(range.to)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<List<Sale>>(
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

                  return Column(
                    children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: 250,
                        child: SummaryCard(
                          label: AppCopy.totalSales,
                          value: formatCurrency(totalSales),
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: SummaryCard(
                          label: AppCopy.totalExpenses,
                          value: formatCurrency(totalExpenses),
                          icon: Icons.receipt_outlined,
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: SummaryCard(
                          label: AppCopy.netProfit,
                          value: formatCurrency(net),
                          icon: Icons.trending_up_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppCopy.backupRestoreTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Pumili ng export/import type. May preview at babala bago i-restore.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _exportJson,
                        child: Text(AppCopy.exportJson),
                      ),
                      OutlinedButton(
                        onPressed: _importJsonDialog,
                        child: Text(AppCopy.importJson),
                      ),
                      OutlinedButton(
                        onPressed: kIsWeb ? null : _exportDb,
                        child: Text(AppCopy.exportDb),
                      ),
                      OutlinedButton(
                        onPressed: kIsWeb ? null : _importDbDialog,
                        child: Text(AppCopy.importDb),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson() async {
    try {
      final path = await _backupService.exportJsonFile();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Na-export ang JSON backup: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _exportDb() async {
    try {
      final path = await _backupService.exportDatabaseFile();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Na-export ang DB backup: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _importJsonDialog() async {
    final mode = await _askMode();
    if (mode == null) return;
    try {
      await _backupService.importPickedJson(replaceAll: mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mode ? 'Na-restore (replace).' : 'Na-restore (merge).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _importDbDialog() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DB import/export ay hindi supported sa web. JSON ang gamitin.')),
      );
      return;
    }

    final mode = await _askMode();
    if (mode == null) return;
    try {
      await _backupService.importDatabaseFile(replaceAll: mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Na-import ang DB file. I-restart ang app kung kailangan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<bool?> _askMode() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Piliin ang restore mode'),
        content: const Text('Babala: Ang "Palitan lahat" ay bubura ng kasalukuyang records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppCopy.mergeMode),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppCopy.replaceMode),
          ),
        ],
      ),
    );
  }
}
