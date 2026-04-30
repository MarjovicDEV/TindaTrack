import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/repositories/tinda_repository.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Benta', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showSaleDialog(),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Mag-record ng benta'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: StreamBuilder<List<dynamic>>(
            stream: widget.repo.watchSales(),
            builder: (context, snapshot) {
              final sales = snapshot.data ?? [];
              if (sales.isEmpty) {
                return const Center(child: Text('Wala pang naitalang benta.'));
              }
              return ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final item = sales[index];
                  return Dismissible(
                    key: ValueKey('sale-${item.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete('Burahin ang benta #${item.id}?'),
                    onDismissed: (_) => widget.repo.deleteSaleAndRestoreStock(item.id),
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
                        onTap: () => _showSaleDialog(existingSale: item),
                        title: Text('Benta #${item.id}'),
                        subtitle: Text(
                          'Transaksyon (PH UTC+8): ${formatPhilippineDateTime(item.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(formatCurrency(item.totalAmount)),
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

  Future<void> _showSaleDialog({dynamic existingSale}) async {
    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController(text: '1');
    int? selectedProductId;
    if (existingSale != null) {
      final items = await widget.repo.getSaleItems(existingSale.id);
      if (items.isNotEmpty) {
        selectedProductId = items.first.productId;
        qtyCtrl.text = items.first.qty.toString();
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingSale == null ? 'Mag-record ng benta' : 'I-update ang benta'),
          content: StreamBuilder(
            stream: widget.repo.watchProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              return Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedProductId,
                      hint: const Text('Pumili ng produkto'),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.name} (${p.unitType}) stock:${p.stockQty.toStringAsFixed(2)}',
                                ),
                              ))
                          .toList(),
                      validator: (v) => v == null ? 'Produkto ay required.' : null,
                      onChanged: (value) => setState(() => selectedProductId = value),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dami / Timbang',
                        helperText: 'kg=decimal, pcs/meter=whole',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (selectedProductId == null) return 'Pumili muna ng produkto.';
                        final product = products.firstWhere((p) => p.id == selectedProductId);
                        final base = product.unitType == 'kg'
                            ? InputValidators.validateDecimalPositive(v ?? '', field: 'Timbang')
                            : InputValidators.validateWholePositive(v ?? '', field: 'Qty');
                        if (base != null) return base;
                        final q = double.tryParse(v ?? '') ?? 0;
                        if (q > product.stockQty) return 'Hindi pwede. Kulang stock.';
                        return null;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselahin'),
            ),
            FilledButton(
              onPressed: () async {
                final products = await widget.repo.watchProducts().first;
                final product = products.firstWhere((p) => p.id == selectedProductId);
                if (!formKey.currentState!.validate()) return;
                final quantity = double.parse(qtyCtrl.text);
                if (existingSale == null) {
                  await widget.repo.createSale(
                    productId: product.id,
                    quantity: quantity,
                  );
                } else {
                  await widget.repo.updateSale(
                    saleId: existingSale.id,
                    productId: product.id,
                    quantity: quantity,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('I-save ang benta'),
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
