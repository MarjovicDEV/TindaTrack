import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../../shared/widgets/summary_card.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 250,
                child: StreamBuilder<double>(
                  stream: repo.watchTotalSales(),
                  builder: (context, snapshot) => SummaryCard(
                    label: 'Total Sales',
                    value: formatCurrency(snapshot.data ?? 0),
                    icon: Icons.payments_outlined,
                  ),
                ),
              ),
              SizedBox(
                width: 250,
                child: StreamBuilder<double>(
                  stream: repo.watchTotalExpenses(),
                  builder: (context, snapshot) => SummaryCard(
                    label: 'Total Expenses',
                    value: formatCurrency(snapshot.data ?? 0),
                    icon: Icons.receipt_outlined,
                  ),
                ),
              ),
              SizedBox(
                width: 250,
                child: StreamBuilder<int>(
                  stream: repo.watchLowStockCount(),
                  builder: (context, snapshot) => SummaryCard(
                    label: 'Low Stock Alerts',
                    value: '${snapshot.data ?? 0}',
                    icon: Icons.warning_amber_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup and Restore', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'This version includes a local snapshot preview to validate your backup data.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final data = await repo.exportSimpleSnapshot();
                      if (!context.mounted) return;
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Backup Snapshot'),
                          content: Text(
                            'Products: ${data[0]}\nSales: ${data[1]}\nCustomers: ${data[2]}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Preview Backup Snapshot'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
