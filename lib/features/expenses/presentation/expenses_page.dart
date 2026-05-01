import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  int _crossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
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
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchExpenses(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Center(child: Text('Wala pang gastos.'));
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.xs),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount(width),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final e = items[index];
                  return _ExpenseCard(
                    item: e,
                    onTap: () => _showExpenseDialog(existing: e),
                    onDelete: () => widget.repo.deleteExpense(e.expense.id),
                    onConfirmDelete: () => _confirmDelete('Burahin ang gastos na "${e.expense.expenseName}"?'),
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
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () => _showAddCategoryDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Magdagdag ng kategorya'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Pangalan ng gastos'),
                    validator: (v) => InputValidators.validateName(v ?? '', field: 'Expense name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'Dahilan'),
                    validator: (v) => InputValidators.validateName(v ?? '', field: 'Reason'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Halaga'),
                    validator: (v) => InputValidators.validateDecimalPositive(v ?? '', field: 'Amount'),
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

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  final ExpenseWithCategory item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<bool?> Function() onConfirmDelete;

  static const List<Color> _headerColors = [
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFF1565C0),
    Color(0xFF00695C),
    Color(0xFFE65100),
    Color(0xFF37474F),
  ];

  Color _headerColor(String seed) =>
      _headerColors[seed.hashCode.abs() % _headerColors.length];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _headerColor(item.categoryName);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 80,
              color: color,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      item.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.expense.expenseName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.expense.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(item.expense.amount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      formatDate(item.expense.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onTap,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'I-edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Burahin',
                    onPressed: () async {
                      final confirmed = await onConfirmDelete();
                      if (confirmed == true) onDelete();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
