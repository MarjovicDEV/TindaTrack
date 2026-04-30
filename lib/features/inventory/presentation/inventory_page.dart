import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/repositories/tinda_repository.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Imbentaryo', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Magdagdag ng produkto'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchProducts(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('Wala pang produkto.'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final low = item.stockQty <= item.lowStockThreshold;
                  return Dismissible(
                    key: ValueKey('product-${item.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(
                      'Burahin ang produktong "${item.name}"?',
                    ),
                    onDismissed: (_) => widget.repo.deleteProduct(item.id),
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
                        onTap: () => _showProductDialog(product: item),
                        title: Text(item.name),
                        subtitle: Text(
                          'Presyo: PHP ${item.price.toStringAsFixed(2)} | Stock: ${item.stockQty.toStringAsFixed(2)} ${item.unitType}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: low
                            ? Chip(
                                backgroundColor: Colors.red.shade100,
                                avatar: const Icon(Icons.warning_amber_outlined, size: 16),
                                label: const Text('Mababang stock'),
                              )
                            : const Chip(label: Text('Ayos')),
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

  Future<void> _showProductDialog({dynamic product}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '1.0');
    final thresholdCtrl = TextEditingController(text: '5.0');
    var unitType = 'pcs';
    if (product != null) {
      nameCtrl.text = product.name;
      priceCtrl.text = product.price.toString();
      stockCtrl.text = product.stockQty.toString();
      thresholdCtrl.text = product.lowStockThreshold.toString();
      unitType = product.unitType;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(product == null ? 'Magdagdag ng produkto' : 'I-update ang produkto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pangalan',
                      helperText: 'Words at spaces lang',
                    ),
                    validator: (v) => InputValidators.validateName(v ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: unitType,
                    decoration: const InputDecoration(
                      labelText: 'Unit of Measure',
                      helperText: 'Basehan ng measurement ng produkto',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                      DropdownMenuItem(value: 'meter', child: Text('meter')),
                    ],
                    validator: (v) => v == null || v.isEmpty ? 'Unit ay required.' : null,
                    onChanged: (v) => setState(() => unitType = v ?? 'pcs'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Presyo',
                      helperText: 'Decimal > 0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        InputValidators.validateDecimalPositive(v ?? '', field: 'Presyo'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: stockCtrl,
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      helperText: unitType == 'pcs' ? 'Whole numbers > 0' : 'Decimal > 0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => unitType == 'pcs'
                        ? InputValidators.validateWholePositive(v ?? '', field: 'Stock')
                        : InputValidators.validateDecimalPositive(v ?? '', field: 'Stock'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: thresholdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Babala sa mababang stock',
                      helperText: 'Decimal > 0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        InputValidators.validateDecimalPositive(v ?? '', field: 'Low stock'),
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

                if (product == null) {
                  await widget.repo.addProduct(
                    name: nameCtrl.text.trim(),
                    price: double.parse(priceCtrl.text),
                    stockQty: double.parse(stockCtrl.text),
                    threshold: double.parse(thresholdCtrl.text),
                    weight: 1,
                    unitType: unitType,
                  );
                } else {
                  await widget.repo.updateProduct(
                    id: product.id,
                    name: nameCtrl.text.trim(),
                    price: double.parse(priceCtrl.text),
                    stockQty: double.parse(stockCtrl.text),
                    threshold: double.parse(thresholdCtrl.text),
                    weight: 1,
                    unitType: unitType,
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
