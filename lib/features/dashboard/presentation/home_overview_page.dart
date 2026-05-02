import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../../shared/widgets/summary_card.dart';

enum _HomeNetPeriod { daily, weekly, monthly }

class HomeOverviewPage extends StatefulWidget {
  const HomeOverviewPage({required this.repo, required this.currencyCode, super.key});

  final TindaRepository repo;
  final String currencyCode;

  @override
  State<HomeOverviewPage> createState() => _HomeOverviewPageState();
}

class _HomeOverviewPageState extends State<HomeOverviewPage> {
  _HomeNetPeriod _period = _HomeNetPeriod.daily;

  ({DateTime from, DateTime to}) _range() {
    final now = DateTime.now();
    switch (_period) {
      case _HomeNetPeriod.daily:
        return (from: DateTime(now.year, now.month, now.day), to: now);
      case _HomeNetPeriod.weekly:
        return (from: now.subtract(const Duration(days: 7)), to: now);
      case _HomeNetPeriod.monthly:
        return (from: DateTime(now.year, now.month - 1, now.day), to: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullW = constraints.maxWidth;
        final range = _range();
        final gap = AppSpacing.sm;
        final useTwoCols = fullW >= 320;
        final colW = useTwoCols ? (fullW - gap) / 2 : fullW;

        Widget cardCol(List<Widget> cards) {
          return SizedBox(
            width: colW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  cards[i],
                ],
              ],
            ),
          );
        }

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
                    Text(AppCopy.navHome, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(AppCopy.summaryTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppCopy.homeNetPeriodLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<_HomeNetPeriod>(
                      segments: const [
                        ButtonSegment(value: _HomeNetPeriod.daily, label: Text(AppCopy.reportFilterDaily)),
                        ButtonSegment(value: _HomeNetPeriod.weekly, label: Text(AppCopy.reportFilterWeekly)),
                        ButtonSegment(value: _HomeNetPeriod.monthly, label: Text(AppCopy.reportFilterMonthly)),
                      ],
                      selected: {_period},
                      onSelectionChanged: (s) => setState(() => _period = s.first),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Saklaw (PH UTC+8): ${formatPhilippineDateTime(range.from)} - ${formatPhilippineDateTime(range.to)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StreamBuilder<List<Sale>>(
                      stream: widget.repo.watchSalesInRange(range.from, range.to),
                      builder: (context, salesSnap) {
                        final salesList = salesSnap.data ?? const <Sale>[];
                        final sales = salesList.fold<double>(0, (a, b) => a + b.totalAmount);
                        return StreamBuilder<List<Expense>>(
                          stream: widget.repo.watchExpensesInRange(range.from, range.to),
                          builder: (context, expSnap) {
                            final expList = expSnap.data ?? const <Expense>[];
                            final expenses = expList.fold<double>(0, (a, b) => a + b.amount);
                            final net = sales - expenses;
                            final scheme = Theme.of(context).colorScheme;

                            return StreamBuilder<int>(
                              stream: widget.repo.watchLowStockCount(),
                              builder: (context, lowSnap) {
                                final low = lowSnap.data ?? 0;

                                final leftCards = <Widget>[
                                  SummaryCard(
                                    label: AppCopy.totalSales,
                                    value: formatCurrency(sales, currencyCode: widget.currencyCode),
                                    icon: Icons.payments_outlined,
                                  ),
                                  SummaryCard(
                                    label: AppCopy.netProfit,
                                    value: formatCurrency(net, currencyCode: widget.currencyCode),
                                    icon: Icons.trending_up_outlined,
                                  ),
                                ];
                                final rightCards = <Widget>[
                                  SummaryCard(
                                    label: AppCopy.totalExpenses,
                                    value: formatCurrency(expenses, currencyCode: widget.currencyCode),
                                    icon: Icons.receipt_outlined,
                                  ),
                                  SummaryCard(
                                    label: AppCopy.lowStockAlerts,
                                    value: '$low',
                                    icon: Icons.inventory_2_outlined,
                                  ),
                                ];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (useTwoCols)
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          cardCol(leftCards),
                                          SizedBox(width: gap),
                                          cardCol(rightCards),
                                        ],
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          leftCards[0],
                                          SizedBox(height: gap),
                                          rightCards[0],
                                          SizedBox(height: gap),
                                          leftCards[1],
                                          SizedBox(height: gap),
                                          rightCards[1],
                                        ],
                                      ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Card(
                                      child: Padding(
                                        padding: AppSpacing.card,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppCopy.homeChartBarSalesExpenses,
                                              style: Theme.of(context).textTheme.titleSmall,
                                            ),
                                            const SizedBox(height: AppSpacing.sm),
                                            SizedBox(
                                              height: math.min(200, fullW * 0.5),
                                              child: _SalesExpensesBar(
                                                sales: sales,
                                                expenses: expenses,
                                                scheme: scheme,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.sm),
                                            Wrap(
                                              spacing: 16,
                                              runSpacing: 8,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                _LegendChip(
                                                  color: scheme.primary,
                                                  label: AppCopy.totalSales,
                                                ),
                                                _LegendChip(
                                                  color: scheme.tertiary,
                                                  label: AppCopy.totalExpenses,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Card(
                                      child: Padding(
                                        padding: AppSpacing.card,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppCopy.homeChartSalesVsExpenses,
                                              style: Theme.of(context).textTheme.titleSmall,
                                            ),
                                            const SizedBox(height: AppSpacing.sm),
                                            SizedBox(
                                              height: math.min(220, fullW * 0.55),
                                              child: _SalesExpensesPie(
                                                sales: sales,
                                                expenses: expenses,
                                                scheme: scheme,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.sm),
                                            Wrap(
                                              spacing: 16,
                                              runSpacing: 8,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                _LegendChip(
                                                  color: scheme.primary,
                                                  label: AppCopy.totalSales,
                                                ),
                                                _LegendChip(
                                                  color: scheme.tertiary,
                                                  label: AppCopy.totalExpenses,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
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

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.square, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SalesExpensesBar extends StatelessWidget {
  const _SalesExpensesBar({
    required this.sales,
    required this.expenses,
    required this.scheme,
  });

  final double sales;
  final double expenses;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (sales <= 0 && expenses <= 0) {
      return const Center(child: Text(AppCopy.noDataRange));
    }

    final maxY = math.max(math.max(sales, expenses) * 1.15, 1.0);
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: sales,
                color: scheme.primary,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: expenses,
                color: scheme.tertiary,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value > meta.max) return const SizedBox.shrink();
                return Text(
                  value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
                  style: bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(AppCopy.totalSales, style: bodySmall, textAlign: TextAlign.center),
                  );
                }
                if (i == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(AppCopy.totalExpenses, style: bodySmall, textAlign: TextAlign.center),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesExpensesPie extends StatelessWidget {
  const _SalesExpensesPie({
    required this.sales,
    required this.expenses,
    required this.scheme,
  });

  final double sales;
  final double expenses;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final total = sales + expenses;
    if (total <= 0) {
      return const Center(child: Text(AppCopy.noDataRange));
    }

    final sections = <PieChartSectionData>[];
    if (sales > 0) {
      sections.add(
        PieChartSectionData(
          color: scheme.primary,
          value: sales,
          title: '${(100 * sales / total).round()}%',
          radius: 72,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    if (expenses > 0) {
      sections.add(
        PieChartSectionData(
          color: scheme.tertiary,
          value: expenses,
          title: '${(100 * expenses / total).round()}%',
          radius: 72,
          titleStyle: TextStyle(
            color: scheme.onTertiary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    if (sections.isEmpty) {
      return const Center(child: Text(AppCopy.noDataRange));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }
}
