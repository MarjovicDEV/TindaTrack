import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/repositories/tinda_repository.dart';

class GroceryPage extends StatefulWidget {
  const GroceryPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Listahan ng Bilihin', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton(
              onPressed: () => _showItemDialog(),
              child: const Text('Magdagdag ng item'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchGroceryItems(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Center(child: Text('Wala pang items.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Dismissible(
                    key: ValueKey('grocery-${item.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete('Burahin ang "${item.name}"?'),
                    onDismissed: (_) => widget.repo.deleteGroceryItem(item.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: CheckboxListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'Qty: ${item.qty.toStringAsFixed(2)} ${item.unitType} • Plan: ${item.plannedDate != null ? formatLongDate(item.plannedDate!) : "N/A"}',
                      ),
                      value: item.isDone,
                      onChanged: (value) => widget.repo.toggleGrocery(item.id, value ?? false),
                      secondary: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showItemDialog(existing: item),
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

  Future<void> _showItemDialog({dynamic existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1.0');
    DateTime? plannedDate;
    var unitType = 'pcs';
    if (existing != null) {
      nameCtrl.text = existing.name;
      qtyCtrl.text = existing.qty.toString();
      plannedDate = existing.plannedDate;
      unitType = existing.unitType;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Magdagdag ng item' : 'I-update ang item'),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Pangalan ng item'),
                  validator: (v) => InputValidators.validateName(v ?? '', field: 'Name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Dami'),
                  validator: (v) =>
                      InputValidators.validateDecimalPositive(v ?? '', field: 'Quantity'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: unitType,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  validator: (v) => v == null || v.isEmpty ? 'Unit ay required.' : null,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                    DropdownMenuItem(value: 'meter', child: Text('meter')),
                  ],
                  onChanged: (v) => setState(() => unitType = v ?? 'pcs'),
                ),
                const SizedBox(height: 8),
                FormField<DateTime>(
                  initialValue: plannedDate,
                  validator: (_) {
                    if (plannedDate == null) return 'Plan date ay required.';
                    final today = DateTime.now();
                    final todayOnly = DateTime(today.year, today.month, today.day);
                    final selected =
                        DateTime(plannedDate!.year, plannedDate!.month, plannedDate!.day);
                    if (selected.isBefore(todayOnly)) {
                      return 'Plan date dapat today o future lang.';
                    }
                    return null;
                  },
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Planong petsa ng bili'),
                        subtitle: Text(
                          plannedDate == null ? 'Pumili ng date' : formatLongDate(plannedDate!),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: () async {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: today,
                              lastDate: DateTime(now.year + 3),
                              initialDate: plannedDate != null && !plannedDate!.isBefore(today)
                                  ? plannedDate!
                                  : today,
                            );
                            if (picked != null) {
                              setState(() => plannedDate = picked);
                              field.didChange(picked);
                            }
                          },
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (existing == null) {
                  await widget.repo.addGroceryItem(
                    nameCtrl.text.trim(),
                    qty: double.parse(qtyCtrl.text),
                    unitType: unitType,
                    plannedDate: plannedDate,
                  );
                } else {
                  await widget.repo.updateGroceryItem(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    qty: double.parse(qtyCtrl.text),
                    unitType: unitType,
                    plannedDate: plannedDate,
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
