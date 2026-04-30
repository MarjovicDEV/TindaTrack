import 'package:flutter/material.dart';

import '../../../core/validators/input_validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/tinda_repository.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Gastos', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton(
              onPressed: () => _showExpenseDialog(),
              child: const Text('Magdagdag ng gastos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchExpenses(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Center(child: Text('Wala pang gastos.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  return Dismissible(
                    key: ValueKey('expense-${e.expense.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete('Burahin ang gastos na "${e.expense.expenseName}"?'),
                    onDismissed: (_) => widget.repo.deleteExpense(e.expense.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      child: ListTile(
                        onTap: () => _showExpenseDialog(existing: e),
                        title: Text('${e.expense.expenseName} (${e.categoryName})'),
                        subtitle: Text('${e.expense.reason} • ${formatDate(e.expense.createdAt)}'),
                        trailing: Text(formatCurrency(e.expense.amount)),
                      ),
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

  Future<void> _showExpenseDialog({dynamic existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.expense.expenseName ?? '');
    final reasonCtrl = TextEditingController(text: existing?.expense.reason ?? '');
    final amountCtrl = TextEditingController();
    int? selectedCategoryId = existing?.expense.categoryId;
    if (existing != null) {
      amountCtrl.text = existing.expense.amount.toString();
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Magdagdag ng gastos' : 'I-update ang gastos'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder(
                    stream: widget.repo.watchExpenseCategories(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                      return Column(
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedCategoryId,
                            hint: const Text('Kategorya'),
                            validator: (v) => v == null ? 'Required ang kategorya.' : null,
                            items: categories
                                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) => setState(() => selectedCategoryId = v),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showAddCategoryDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Magdagdag ng kategorya'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Pangalan ng gastos'),
                    validator: (v) =>
                        InputValidators.validateName(v ?? '', field: 'Expense name'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'Dahilan'),
                    validator: (v) => InputValidators.validateName(v ?? '', field: 'Reason'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Halaga'),
                    validator: (v) =>
                        InputValidators.validateDecimalPositive(v ?? '', field: 'Amount'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (existing == null) {
                  await widget.repo.addExpense(
                    categoryId: selectedCategoryId!,
                    expenseName: nameCtrl.text.trim(),
                    reason: reasonCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text),
                  );
                } else {
                  await widget.repo.updateExpense(
                    expenseId: existing.expense.id,
                    categoryId: selectedCategoryId!,
                    expenseName: nameCtrl.text.trim(),
                    reason: reasonCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text),
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('I-save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Magdagdag ng kategorya'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Pangalan ng kategorya'),
            validator: (v) => InputValidators.validateName(v ?? '', field: 'Category'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await widget.repo.addExpenseCategory(ctrl.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('I-save'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kumpirmahin ang delete'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hindi')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
