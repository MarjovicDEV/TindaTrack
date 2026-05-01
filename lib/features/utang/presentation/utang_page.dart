import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/validators/input_validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';

class UtangPage extends StatefulWidget {
  const UtangPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<UtangPage> createState() => _UtangPageState();
}

class _UtangPageState extends State<UtangPage> {
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
            Text('Utang', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton(
              onPressed: () => _showAddCustomer(context),
              child: const Text('Magdagdag'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchCustomerBalances(),
            builder: (context, snapshot) {
              final customers = snapshot.data ?? [];
              if (customers.isEmpty) return const Center(child: Text('Wala pang customer.'));
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.xs),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount(width),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.9,
                ),
                itemCount: customers.length,
                itemBuilder: (_, index) {
                  final customer = customers[index];
                  return _CustomerCard(
                    customer: customer,
                    onTap: () => _showEntries(customer.customerId, customer.name),
                    onEdit: () => _showEditCustomer(customer.customerId, customer.name),
                    onAddEntry: () => _showAddEntry(context, customer.customerId),
                    onDelete: () => widget.repo.deleteCustomer(customer.customerId),
                    onConfirmDelete: () => _confirmDelete('Burahin si ${customer.name}?'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddCustomer(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final qtyCtrls = <int, TextEditingController>{};
    final selected = <int>{};
    DateTime? dueDate = DateTime.now();
    final rootContext = context;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Magdagdag ng customer'),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SizedBox(
              width: 520,
              child: StreamBuilder(
                stream: widget.repo.watchProducts(),
                builder: (context, snapshot) {
                  final products = snapshot.data ?? [];
                  double total = 0;
                  for (final product in products) {
                    if (!selected.contains(product.id)) continue;
                    final qty = double.tryParse(qtyCtrls[product.id]?.text.trim() ?? '');
                    if (qty == null) continue;
                    total += qty * product.price;
                  }
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Pangalan'),
                          validator: (v) => InputValidators.validateName(v ?? ''),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FormField<Set<int>>(
                          initialValue: selected,
                          validator: (_) =>
                              selected.isEmpty ? 'Pumili ng kahit isang item.' : null,
                          builder: (field) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Unang item na inutang'),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (products.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Wala pang produkto sa Imbentaryo. Magdagdag muna bago gumawa ng bulk utang.',
                                  ),
                                ),
                              ...products.map((product) {
                                final checked = selected.contains(product.id);
                                qtyCtrls.putIfAbsent(product.id, () => TextEditingController());
                                return Row(
                                  children: [
                                    Checkbox(
                                      value: checked,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v ?? false) {
                                            selected.add(product.id);
                                            final ctrl = qtyCtrls[product.id];
                                            if (ctrl != null && ctrl.text.trim().isEmpty) {
                                              ctrl.text = product.unitType == 'pcs' ? '1' : '1.0';
                                            }
                                          } else {
                                            selected.remove(product.id);
                                          }
                                        });
                                        field.didChange(selected);
                                      },
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${product.name} (${product.unitType}) PHP ${product.price.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    SizedBox(
                                      width: 110,
                                      child: TextFormField(
                                        controller: qtyCtrls[product.id],
                                        keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: const InputDecoration(labelText: 'Qty'),
                                        enabled: checked,
                                        validator: (v) {
                                          if (!checked) return null;
                                          if (product.unitType == 'pcs') {
                                            return InputValidators.validateWholePositive(
                                              v ?? '',
                                              field: 'Qty',
                                            );
                                          }
                                          return InputValidators.validateDecimalPositive(
                                            v ?? '',
                                            field: 'Qty',
                                          );
                                        },
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              if (field.hasError)
                                Text(
                                  field.errorText!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          initialValue: total.toStringAsFixed(2),
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Unang amount ng utang'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FormField<DateTime>(
                          initialValue: dueDate,
                          validator: (_) {
                            if (dueDate == null) return 'Due date ay required.';
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final selected =
                                DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
                            if (selected.isBefore(today)) {
                              return 'Due date dapat today o future lang.';
                            }
                            return null;
                          },
                          builder: (field) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Due date ng utang'),
                                subtitle: Text(
                                  dueDate == null ? 'Pumili ng due date' : formatLongDate(dueDate!),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.calendar_month_outlined),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final today = DateTime(now.year, now.month, now.day);
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: today,
                                      lastDate: DateTime(now.year + 5),
                                      initialDate: dueDate != null && !dueDate!.isBefore(today)
                                          ? dueDate!
                                          : today,
                                    );
                                    if (picked != null) {
                                      setState(() => dueDate = picked);
                                      field.didChange(picked);
                                    }
                                  },
                                ),
                              ),
                              if (field.hasError)
                                Text(
                                  field.errorText!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            FilledButton(
              onPressed: () async {
                final products = await widget.repo.watchProducts().first;
                if (products.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Magdagdag muna ng produkto sa Imbentaryo.')),
                  );
                  return;
                }
                if (!formKey.currentState!.validate()) return;
                final lines = <UtangLineInput>[];
                for (final productId in selected) {
                  final qty = double.tryParse(qtyCtrls[productId]?.text.trim() ?? '');
                  if (qty == null) continue;
                  lines.add(UtangLineInput(productId: productId, qty: qty));
                }
                if (lines.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ilagay ang valid na quantity ng napiling item.')),
                  );
                  return;
                }
                try {
                  final customerId = await widget.repo.addCustomer(nameCtrl.text.trim());
                  await widget.repo.addUtangWithItems(
                    customerId: customerId,
                    lines: lines,
                    dueDate: dueDate,
                    note: 'Initial utang',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hindi na-save: $e')));
                  return;
                }
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(rootContext);
              },
              child: const Text('I-save ang customer'),
            ),
          ],
        ),
      ),
    );
    for (final ctrl in qtyCtrls.values) {
      ctrl.dispose();
    }
  }

  Future<void> _showAddEntry(BuildContext context, int customerId) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final qtyCtrls = <int, TextEditingController>{};
    final selected = <int>{};
    var isPayment = false;
    DateTime? dueDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Magdagdag ng utang entry'),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SizedBox(
              width: 520,
              child: StreamBuilder(
                stream: widget.repo.watchProducts(),
                builder: (context, snapshot) {
                  final products = snapshot.data ?? [];
                  double computedTotal = 0;
                  if (!isPayment) {
                    for (final product in products) {
                      if (!selected.contains(product.id)) continue;
                      final qty = double.tryParse(qtyCtrls[product.id]?.text.trim() ?? '');
                      if (qty == null) continue;
                      computedTotal += qty * product.price;
                    }
                  }
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          title: Text(isPayment ? 'Bayad' : 'Bagong Utang'),
                          subtitle: Text(
                            isPayment ? 'Bawas sa balanse' : 'Dagdag sa balanse',
                          ),
                          value: isPayment,
                          onChanged: (v) => setState(() => isPayment = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (isPayment)
                          TextFormField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Amount'),
                            validator: (v) => InputValidators.validateDecimalPositive(
                              v ?? '',
                              field: 'Amount',
                            ),
                          ),
                        if (!isPayment) ...[
                          FormField<Set<int>>(
                            initialValue: selected,
                            validator: (_) =>
                                selected.isEmpty ? 'Pumili ng kahit isang item.' : null,
                            builder: (field) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Item / Product'),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (products.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Wala pang produkto sa Imbentaryo. Magdagdag muna bago gumawa ng bulk utang.',
                                    ),
                                  ),
                                ...products.map((product) {
                                  final checked = selected.contains(product.id);
                                  qtyCtrls.putIfAbsent(product.id, () => TextEditingController());
                                  return Row(
                                    children: [
                                      Checkbox(
                                        value: checked,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v ?? false) {
                                              selected.add(product.id);
                                              final ctrl = qtyCtrls[product.id];
                                              if (ctrl != null && ctrl.text.trim().isEmpty) {
                                                ctrl.text =
                                                    product.unitType == 'pcs' ? '1' : '1.0';
                                              }
                                            } else {
                                              selected.remove(product.id);
                                            }
                                          });
                                          field.didChange(selected);
                                        },
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '${product.name} (${product.unitType}) PHP ${product.price.toStringAsFixed(2)}',
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      SizedBox(
                                        width: 110,
                                        child: TextFormField(
                                          controller: qtyCtrls[product.id],
                                          keyboardType: const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                          decoration: const InputDecoration(labelText: 'Qty'),
                                          enabled: checked,
                                          validator: (v) {
                                            if (!checked) return null;
                                            if (product.unitType == 'pcs') {
                                              return InputValidators.validateWholePositive(
                                                v ?? '',
                                                field: 'Qty',
                                              );
                                            }
                                            return InputValidators.validateDecimalPositive(
                                              v ?? '',
                                              field: 'Qty',
                                            );
                                          },
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                if (field.hasError)
                                  Text(
                                    field.errorText!,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            initialValue: computedTotal.toStringAsFixed(2),
                            enabled: false,
                            decoration: const InputDecoration(labelText: 'Amount (auto)'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FormField<DateTime>(
                            initialValue: dueDate,
                            validator: (_) {
                              if (isPayment) return null;
                              if (dueDate == null) return 'Due date ay required.';
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              final selected =
                                  DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
                              if (selected.isBefore(today)) {
                                return 'Due date dapat today o future lang.';
                              }
                              return null;
                            },
                            builder: (field) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Due date ng utang'),
                                  subtitle: Text(
                                    dueDate == null
                                        ? 'Pumili ng due date'
                                        : formatLongDate(dueDate!),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.calendar_month_outlined),
                                    onPressed: () async {
                                      final now = DateTime.now();
                                      final today = DateTime(now.year, now.month, now.day);
                                      final picked = await showDatePicker(
                                        context: context,
                                        firstDate: today,
                                        lastDate: DateTime(now.year + 5),
                                        initialDate: dueDate != null &&
                                                !dueDate!.isBefore(today)
                                            ? dueDate!
                                            : today,
                                      );
                                      if (picked != null) {
                                        setState(() => dueDate = picked);
                                        field.didChange(picked);
                                      }
                                    },
                                  ),
                                ),
                                if (field.hasError)
                                  Text(
                                    field.errorText!,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: noteCtrl,
                          decoration: const InputDecoration(labelText: 'Note'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            FilledButton(
              onPressed: () async {
                final products = await widget.repo.watchProducts().first;
                if (!isPayment && products.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Magdagdag muna ng produkto sa Imbentaryo.')),
                  );
                  return;
                }
                if (!formKey.currentState!.validate()) return;
                if (isPayment) {
                  final amount = double.parse(amountCtrl.text);
                  await widget.repo.addUtang(
                    customerId: customerId,
                    amount: amount,
                    isPayment: true,
                    dueDate: null,
                    itemName: null,
                    note: noteCtrl.text.trim().isEmpty
                        ? 'Payment received'
                        : noteCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Na-save: ${formatCurrency(amount)}')));
                  }
                  return;
                }
                final lines = <UtangLineInput>[];
                for (final productId in selected) {
                  final qty = double.tryParse(qtyCtrls[productId]?.text.trim() ?? '');
                  if (qty == null) continue;
                  lines.add(UtangLineInput(productId: productId, qty: qty));
                }
                if (lines.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ilagay ang valid na quantity ng napiling item.')),
                  );
                  return;
                }
                try {
                  await widget.repo.addUtangWithItems(
                    customerId: customerId,
                    lines: lines,
                    dueDate: dueDate,
                    note: noteCtrl.text.trim().isEmpty ? 'Utang recorded' : noteCtrl.text.trim(),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hindi na-save: $e')));
                  return;
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Na-save ang utang entry')),
                  );
                }
              },
              child: const Text('I-save ang entry'),
            ),
          ],
        ),
      ),
    );
    for (final ctrl in qtyCtrls.values) {
      ctrl.dispose();
    }
  }

  Future<void> _showEditCustomer(int customerId, String currentName) async {
    final formKey = GlobalKey<FormState>();
    final rootContext = context;
    final ctrl = TextEditingController(text: currentName);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('I-update ang customer'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Pangalan'),
            validator: (v) => InputValidators.validateName(v ?? ''),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await widget.repo.updateCustomer(customerId, ctrl.text.trim());
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(rootContext);
            },
            child: const Text('I-save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEntries(int customerId, String name) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text('Entries ni $name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: StreamBuilder(
                  stream: widget.repo.watchUtangEntriesByCustomer(customerId),
                  builder: (context, snapshot) {
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) return const Center(child: Text('Wala pang entries.'));
                    return ListView.builder(
                      controller: controller,
                      itemCount: entries.length,
                      itemBuilder: (_, index) {
                        final e = entries[index];
                        return Dismissible(
                          key: ValueKey('utang-${e.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete('Burahin ang entry na ito?'),
                          onDismissed: (_) => widget.repo.deleteUtangEntry(e.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            child: ListTile(
                              onTap: () => _showEntryDetailModal(e),
                              title: Text(e.itemName ?? (e.isPayment ? 'Bayad' : 'Utang')),
                              subtitle: Text(
                                'Transaksyon (PH UTC+8): ${formatPhilippineDateTime(e.createdAt)}'
                                '${e.dueDate != null ? ' • Due: ${formatLongDate(e.dueDate!)}' : ''}'
                                '${(e.note ?? '').isNotEmpty ? '\n${e.note}' : ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${e.isPayment ? '-' : '+'}${formatCurrency(e.amount)}'),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showEditEntry(e),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  Future<void> _showEditEntry(dynamic entry) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: entry.amount.toString());
    final itemCtrl = TextEditingController(text: entry.itemName ?? '');
    final noteCtrl = TextEditingController(text: entry.note ?? '');
    var isPayment = entry.isPayment;
    DateTime? dueDate = entry.dueDate;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('I-update ang utang entry'),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (v) =>
                      InputValidators.validateDecimalPositive(v ?? '', field: 'Amount'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: itemCtrl,
                  decoration: const InputDecoration(labelText: 'Item / Product'),
                  validator: (v) => InputValidators.validateName(v ?? '', field: 'Item'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: AppSpacing.md),
                FormField<DateTime>(
                  initialValue: dueDate,
                  validator: (_) {
                    if (isPayment) return null;
                    if (dueDate == null) return 'Due date ay required.';
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final selected = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
                    if (selected.isBefore(today)) {
                      return 'Due date dapat today o future lang.';
                    }
                    return null;
                  },
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due date ng utang'),
                        subtitle: Text(
                          dueDate == null ? 'Pumili ng due date' : formatLongDate(dueDate!),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: () async {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: today,
                              lastDate: DateTime(now.year + 5),
                              initialDate:
                                  dueDate != null && !dueDate!.isBefore(today) ? dueDate! : today,
                            );
                            if (picked != null) {
                              setState(() => dueDate = picked);
                              field.didChange(picked);
                            }
                          },
                        ),
                      ),
                      if (field.hasError)
                        Text(
                          field.errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: Text(isPayment ? 'Bayad' : 'Bagong Utang'),
                  value: isPayment,
                  onChanged: (v) => setState(() => isPayment = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await widget.repo.updateUtangEntry(
                  entryId: entry.id,
                  amount: double.parse(amountCtrl.text),
                  isPayment: isPayment,
                  dueDate: isPayment ? null : dueDate,
                  itemName: itemCtrl.text.trim().isEmpty ? null : itemCtrl.text.trim(),
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('I-save ang entry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEntryDetailModal(dynamic entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalye ng Entry', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${entry.isPayment ? 'Bayad' : 'Utang'} • ${formatCurrency(entry.amount)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Transaksyon (PH UTC+8): ${formatPhilippineDateTime(entry.createdAt)}'
                '${entry.dueDate != null ? '\nDue date: ${formatLongDate(entry.dueDate!)}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (entry.isPayment)
                Text(
                  'Walang item breakdown para sa bayad entry.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (!entry.isPayment)
                Expanded(
                  child: StreamBuilder(
                    stream: widget.repo.watchUtangEntryItems(entry.id),
                    builder: (context, snapshot) {
                      final lines = snapshot.data ?? [];
                      if (lines.isEmpty) {
                        return const Center(child: Text('Walang line items.'));
                      }
                      return ListView.separated(
                        controller: controller,
                        itemCount: lines.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final line = lines[i];
                          final qtyLabel = line.unitType == 'pcs'
                              ? line.qty.toInt().toString()
                              : line.qty.toStringAsFixed(2);
                          return ListTile(
                            title: Text(line.productName),
                            subtitle: Text(
                              'Qty: $qtyLabel ${line.unitType} • Unit: ${formatCurrency(line.unitPrice)}',
                            ),
                            trailing: Text(formatCurrency(line.lineTotal)),
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onAddEntry,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  final CustomerBalance customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onAddEntry;
  final VoidCallback onDelete;
  final Future<bool?> Function() onConfirmDelete;

  static const List<Color> _headerColors = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF2E7D32),
    Color(0xFFBF360C),
    Color(0xFF00695C),
    Color(0xFF37474F),
  ];

  Color _headerColor(String seed) =>
      _headerColors[seed.hashCode.abs() % _headerColors.length];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _headerColor(customer.name);
    final hasDebt = customer.balance > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 90,
              color: color,
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
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
                      customer.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'Balanse:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      formatCurrency(customer.balance),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: hasDebt ? cs.error : cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
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
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: onAddEntry,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Magdagdag ng utang',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
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
