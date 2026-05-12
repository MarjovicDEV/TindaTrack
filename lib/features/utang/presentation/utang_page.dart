import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validators/input_validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../../features/receipts/application/receipt_pdf_builder.dart';
import '../../../shared/widgets/receipt_sheet.dart';
import '../../reports/presentation/report_export_stub.dart'
    if (dart.library.io) '../../reports/presentation/report_export_io.dart' as report_export;

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
    final copy = AppCopy.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(copy.navUtang),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showAddCustomer(context),
                  icon: const Icon(Icons.person_add_outlined),
                   label: Text(copy.utangAdd),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder(
                    stream: widget.repo.watchCustomerBalances(),
                    builder: (context, snapshot) {
                      final customers = snapshot.data ?? [];
                      if (customers.isEmpty) {
                        return Center(
                          child: Text(
                             copy.isEnglish ? 'No customers yet.' : 'Wala pang customer.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _crossAxisCount(width),
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: customers.length,
                        itemBuilder: (_, index) {
                          final customer = customers[index];
                          return _CustomerCard(
                            customer: customer,
                            onTap: () => _showEntries(customer.customerId, customer.name),
                            onEdit: () => _showEditCustomer(customer.customerId, customer.name),
                            onAddEntry: () => _showAddEntry(context, customer.customerId, customer.balance),
                            onDelete: () => widget.repo.deleteCustomer(customer.customerId),
                            onConfirmDelete: () => _confirmDelete(
                              copy.isEnglish ? 'Delete ${customer.name}?' : 'Burahin si ${customer.name}?',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCustomer(BuildContext context) async {
    final copy = AppCopy.of(context);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final qtyCtrls = <int, TextEditingController>{};
    final selected = <int>{};
    DateTime? dueDate = DateTime.now();
    final newEntryId = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(copy.utangAddCustomerTitle),
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
                          decoration: InputDecoration(labelText: copy.utangName),
                          validator: (v) => InputValidators.validateName(v ?? ''),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FormField<Set<int>>(
                          initialValue: selected,
                          validator: (_) =>
                              selected.isEmpty ? copy.utangSelectAtLeastOneItem : null,
                          builder: (field) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(copy.utangFirstBorrowedItem),
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
                                  child: Text(copy.utangNoInventoryPrompt),
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
                                        decoration: InputDecoration(labelText: copy.utangQty),
                                        enabled: checked,
                                        validator: (v) {
                                          if (!checked) return null;
                                          if (product.unitType == 'pcs') {
                                            return InputValidators.validateWholePositive(
                                              v ?? '',
                                              field: copy.utangQty,
                                            );
                                          }
                                          return InputValidators.validateDecimalPositive(
                                            v ?? '',
                                            field: copy.utangQty,
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
                          decoration: InputDecoration(labelText: copy.utangInitialAmount),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FormField<DateTime>(
                          initialValue: dueDate,
                          validator: (_) {
                            if (dueDate == null) return copy.utangDueDateRequired;
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
                                  dueDate == null ? copy.utangPickDueDate : formatLongDate(dueDate!),
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.inventoryCancel)),
            FilledButton(
              onPressed: () async {
                final products = await widget.repo.watchProducts().first;
                if (products.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(copy.utangAddProductInventoryPrompt)),
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
                    SnackBar(content: Text(copy.utangInvalidSelectedQty)),
                  );
                  return;
                }
                try {
                  final customerId = await widget.repo.addCustomer(nameCtrl.text.trim());
                  final entryId = await widget.repo.addUtangWithItems(
                    customerId: customerId,
                    lines: lines,
                    dueDate: dueDate,
                    note: copy.utangInitialDebtNote,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, entryId);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                    ).showSnackBar(SnackBar(content: Text('${copy.utangSaveFailedPrefix} $e')));
                  return;
                }
              },
              child: Text(copy.utangSaveCustomer),
            ),
          ],
        ),
      ),
    );
    for (final ctrl in qtyCtrls.values) {
      ctrl.dispose();
    }
    if (newEntryId != null && mounted) {
      await _showUtangReceipt(newEntryId);
    }
  }

  String? _validatePaymentAmount(
    AppCopy copy,
    String? raw,
    double maxAllowed,
  ) {
    final base = InputValidators.validateDecimalPositive(raw ?? '', field: copy.utangAmount);
    if (base != null) return base;
    if (maxAllowed <= 0) return copy.utangNoDebtToPay;
    final amount = double.parse(raw!.trim());
    if (amount > maxAllowed + 1e-9) {
      return copy.utangPaymentExceedsBalance(formatCurrency(maxAllowed));
    }
    return null;
  }

  Future<void> _showAddEntry(BuildContext context, int customerId, double customerBalance) async {
    final copy = AppCopy.of(context);
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final qtyCtrls = <int, TextEditingController>{};
    final selected = <int>{};
    var isPayment = false;
    DateTime? dueDate = DateTime.now();

    final entryIdResult = await showDialog<int?>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(copy.utangAddEntryTitle),
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
                           title: Text(isPayment ? copy.utangPayment : copy.utangNewDebt),
                           subtitle: Text(
                             isPayment ? copy.utangPaymentSubtitle : copy.utangDebtSubtitle,
                           ),
                          value: isPayment,
                          onChanged: (v) {
                            setState(() => isPayment = v);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              formKey.currentState?.validate();
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (isPayment)
                          TextFormField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: copy.utangAmount,
                              helperText: customerBalance > 0
                                  ? '${copy.utangPaymentMaxLabel} ${formatCurrency(customerBalance)}'
                                  : copy.utangNoDebtToPay,
                            ),
                            validator: (v) => _validatePaymentAmount(copy, v, customerBalance),
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
                                                field: copy.utangQty,
                                              );
                                            }
                                            return InputValidators.validateDecimalPositive(
                                              v ?? '',
                                                field: copy.utangQty,
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
                              if (dueDate == null) return copy.utangDueDateRequired;
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              final selected =
                                  DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
                                if (selected.isBefore(today)) {
                                  return copy.utangDueDateTodayOrFuture;
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
                                        ? copy.utangPickDueDate
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
                  final newId = await widget.repo.addUtangWithItems(
                    customerId: customerId,
                    lines: lines,
                    dueDate: dueDate,
                    note: noteCtrl.text.trim().isEmpty ? 'Utang recorded' : noteCtrl.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, newId);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hindi na-save: $e')));
                  return;
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
    if (entryIdResult != null && mounted) {
      await _showUtangReceipt(entryIdResult);
    }
  }

  Future<void> _showEditCustomer(int customerId, String currentName) async {
    final copy = AppCopy.of(context);
    final formKey = GlobalKey<FormState>();
    final rootContext = context;
    final ctrl = TextEditingController(text: currentName);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(copy.isEnglish ? 'Update customer' : 'I-update ang customer'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: ctrl,
            decoration: InputDecoration(labelText: copy.utangName),
            validator: (v) => InputValidators.validateName(v ?? '', field: copy.utangName),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.inventoryCancel)),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await widget.repo.updateCustomer(customerId, ctrl.text.trim());
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(rootContext);
            },
            child: Text(copy.inventorySave),
          ),
        ],
      ),
    );
  }

  Future<void> _showEntries(int customerId, String name) async {
    final copy = AppCopy.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(copy.entriesForCustomer(name), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: StreamBuilder(
                  stream: widget.repo.watchUtangEntriesByCustomer(customerId),
                  builder: (context, snapshot) {
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) return Center(child: Text(copy.utangNoEntriesYet));
                    return ListView.builder(
                      controller: controller,
                      itemCount: entries.length,
                      itemBuilder: (_, index) {
                        final e = entries[index];
                        return Dismissible(
                          key: ValueKey('utang-${e.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(
                            copy.isEnglish ? 'Delete this entry?' : 'Burahin ang entry na ito?',
                          ),
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
                              isThreeLine: true,
                              onTap: () => _showEntryDetailModal(e),
                              title: Text(
                                e.itemName ?? (e.isPayment ? copy.utangPayment : copy.utangNewDebt),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${copy.utangTransactionLabel} ${formatPhilippineDateTime(e.createdAt)}'
                                '${e.dueDate != null ? ' • ${copy.utangDueDateLabelShort} ${formatLongDate(e.dueDate!)}' : ''}'
                                '${(e.note ?? '').isNotEmpty ? '\n${e.note}' : ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: SizedBox(
                                width: e.isPayment ? 118 : 158,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${e.isPayment ? '-' : '+'}${formatCurrency(e.amount)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                    if (!e.isPayment)
                                      IconButton(
                                        icon: const Icon(Icons.receipt_outlined),
                                        tooltip: copy.utangReceiptTitle,
                                        onPressed: () => _showUtangReceipt(e.id),
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                                        padding: EdgeInsets.zero,
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showEditEntry(e),
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
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

  Future<void> _showEditEntry(UtangEntry entry) async {
    final copy = AppCopy.of(context);
    final balances = await widget.repo.watchCustomerBalances().first;
    var openingBalance = 0.0;
    for (final c in balances) {
      if (c.customerId == entry.customerId) {
        openingBalance = c.balance;
        break;
      }
    }

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: entry.amount.toString());
    final itemCtrl = TextEditingController(text: entry.itemName ?? '');
    final noteCtrl = TextEditingController(text: entry.note ?? '');
    DateTime? dueDate = entry.dueDate;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(copy.isEnglish ? 'Update debt entry' : 'I-update ang utang entry'),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: copy.utangAmount,
                    helperText: entry.isPayment
                        ? (() {
                            final maxPay = openingBalance + entry.amount;
                            if (maxPay <= 0) return copy.utangNoDebtToPay;
                            return '${copy.utangPaymentMaxLabel} ${formatCurrency(maxPay)}';
                          })()
                        : null,
                  ),
                  validator: (v) {
                    if (!entry.isPayment) {
                      return InputValidators.validateDecimalPositive(v ?? '', field: copy.utangAmount);
                    }
                    final maxPay = openingBalance + entry.amount;
                    return _validatePaymentAmount(copy, v, maxPay);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: itemCtrl,
                  decoration: InputDecoration(labelText: copy.utangItemProduct),
                  validator: (v) => entry.isPayment
                      ? null
                      : InputValidators.validateName(v ?? '', field: copy.utangItemProduct),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: copy.utangNote),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!entry.isPayment)
                  FormField<DateTime>(
                    initialValue: dueDate,
                    validator: (_) {
                      if (dueDate == null) return copy.utangDueDateRequired;
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
                                title: Text(copy.utangDueDateLabel),
                                subtitle: Text(
                                  dueDate == null ? copy.utangPickDueDate : formatLongDate(dueDate!),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    entry.isPayment ? Icons.payments_outlined : Icons.receipt_long_outlined,
                  ),
                  title: Text(entry.isPayment ? copy.utangPayment : copy.utangNewDebt),
                  subtitle: Text(
                    copy.utangEntryTypeLockedHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.inventoryCancel)),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await widget.repo.updateUtangEntry(
                    entryId: entry.id,
                    amount: double.parse(amountCtrl.text),
                    isPayment: entry.isPayment,
                    dueDate: entry.isPayment ? null : dueDate,
                    itemName: itemCtrl.text.trim().isEmpty ? null : itemCtrl.text.trim(),
                    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                  );
                } on StateError catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  return;
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  return;
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(copy.utangSaveEntry),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEntryDetailModal(dynamic entry) async {
    final copy = AppCopy.of(context);
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      copy.utangDetailTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!entry.isPayment)
                    IconButton(
                      icon: const Icon(Icons.receipt_outlined),
                      tooltip: copy.utangReceiptTitle,
                      onPressed: () async {
                        Navigator.pop(context);
                        await Future<void>.delayed(Duration.zero);
                        if (mounted) await _showUtangReceipt(entry.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${entry.isPayment ? copy.utangPayment : copy.utangNewDebt} • ${formatCurrency(entry.amount)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${copy.utangTransactionLabel} ${formatPhilippineDateTime(entry.createdAt)}'
                '${entry.dueDate != null ? '\n${copy.utangDueDateLabelShort} ${formatLongDate(entry.dueDate!)}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (entry.isPayment)
                Text(
                  copy.utangNoBreakdownForPayment,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (!entry.isPayment)
                Expanded(
                  child: StreamBuilder(
                    stream: widget.repo.watchUtangEntryItems(entry.id),
                    builder: (context, snapshot) {
                      final lines = snapshot.data ?? [];
                      if (lines.isEmpty) {
                        return Center(child: Text(copy.utangNoLineItems));
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
                              '${copy.utangQtyShort}: $qtyLabel ${line.unitType} • ${copy.utangUnitLabel} ${formatCurrency(line.unitPrice)}',
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

  Future<void> _showUtangReceipt(int entryId) async {
    final copy = AppCopy.of(context);
    final receipt = await widget.repo.getUtangReceipt(entryId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: ReceiptSheet(
            model: ReceiptViewModel(
              title: copy.utangReceiptTitle,
              customerName: receipt.customerName,
              createdAt: receipt.entry.createdAt,
              dueDate: receipt.entry.dueDate,
              totalAmount: receipt.entry.amount,
              lines: receipt.lines
                  .map(
                    (line) => ReceiptLineItem(
                      productName: line.productName,
                      qtyLabel: line.qty.toStringAsFixed(2),
                      unitType: line.unitType,
                      unitPriceLabel: formatCurrency(line.unitPrice),
                      lineTotalLabel: formatCurrency(line.lineTotal),
                    ),
                  )
                  .toList(),
            ),
            onExportPngBytes: kIsWeb
                ? null
                : (bytes) => _writeUtangReceiptPng(bytes, copy),
            onExportPdf: () => _exportUtangPdf(receipt, copy),
          ),
        ),
      ),
    );
  }

  Future<void> _writeUtangReceiptPng(Uint8List bytes, AppCopy copy) async {
    final path = await report_export.writeReportPngBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copy.reportPngSaved(path))),
    );
  }

  Future<void> _exportUtangPdf(UtangReceiptDetail receipt, AppCopy copy) async {
    try {
      final bytes = await ReceiptPdfBuilder.buildUtangReceiptBytes(
        title: copy.utangReceiptTitle,
        receipt: receipt,
        currencyCode: 'PHP',
        labelCustomer: copy.receiptCustomerLabel,
        labelTotal: copy.receiptTotalLabel,
        labelTransaction: copy.receiptTransactionLabel,
        labelDueDate: copy.receiptDueDateLabel,
        colItem: copy.receiptColItem,
        colQty: copy.receiptColQty,
        colUnitPrice: copy.receiptColUnitPrice,
        colLineTotal: copy.receiptColLineTotal,
      );
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(copy.reportPdfDownloadSoon(bytes.length))),
        );
        return;
      }
      final path = await report_export.writeReportPdfBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.reportPdfSaved(path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.reportExportError('$e'))),
      );
    }
  }

  Future<bool?> _confirmDelete(String message) {
    final copy = AppCopy.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(copy.inventoryConfirmDeleteTitle),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(copy.inventoryDeleteNo)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.inventoryDeleteYes),
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
    final copy = AppCopy.of(context);
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
              height: 76,
              color: color,
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 40,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        children: [
                          TextSpan(text: '${copy.utangBalance} '),
                          TextSpan(
                            text: formatCurrency(customer.balance),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: hasDebt ? cs.error : cs.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 2, bottom: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: onAddEntry,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(36, 36),
                      padding: const EdgeInsets.all(4),
                    ),
                    tooltip: copy.utangAddDebtTooltip,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(36, 36),
                      padding: const EdgeInsets.all(4),
                    ),
                    tooltip: copy.utangEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(36, 36),
                      padding: const EdgeInsets.all(4),
                    ),
                    tooltip: copy.utangDelete,
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
