import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/tinda_repository.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Expenses', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton(
              onPressed: () => _showAddExpense(context),
              child: const Text('Add Expense'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: repo.watchExpenses(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Center(child: Text('No expenses yet.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  return Card(
                    child: ListTile(
                      title: Text(e.category),
                      subtitle: Text(formatDate(e.createdAt)),
                      trailing: Text(formatCurrency(e.amount)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddExpense(BuildContext context) async {
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final category = categoryCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (category.isEmpty || amount <= 0) return;
              await repo.addExpense(category: category, amount: amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
