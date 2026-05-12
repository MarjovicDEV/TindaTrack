import 'package:flutter/material.dart';

import '../../../core/resources/app_copy.dart';
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
    final copy = AppCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(copy.navSales),
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
                  onPressed: () => _showSaleDialog(),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(copy.isEnglish ? 'Record sale' : 'Mag-record ng benta'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder<List<dynamic>>(
                    stream: widget.repo.watchSales(),
                    builder: (context, snapshot) {
                      final sales = snapshot.data ?? [];
                      if (sales.isEmpty) {
                        return Center(
                          child: Text(
                            copy.isEnglish ? 'No sales yet recorded.' : 'Wala pang naitalang benta.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: sales.length,
                        itemBuilder: (context, index) {
                          final item = sales[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Dismissible(
                              key: ValueKey('sale-${item.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(
                                copy.isEnglish ? 'Delete sale #${item.id}?' : 'Burahin ang benta #${item.id}?',
                              ),
                              onDismissed: (_) =>
                                  widget.repo.deleteSaleAndRestoreStock(item.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: scheme.outlineVariant),
                                ),
                                child: ListTile(
                                  onTap: () => _showSaleDialog(existingSale: item),
                                   title: Text(copy.isEnglish ? 'Sale #${item.id}' : 'Benta #${item.id}'),
                                   subtitle: Text(
                                     '${copy.isEnglish ? 'Transaction' : 'Transaksyon'} (PH UTC+8): ${formatPhilippineDateTime(item.createdAt)}',
                                     style: Theme.of(context).textTheme.bodySmall,
                                   ),
                                  trailing: Text(formatCurrency(item.totalAmount)),
                                ),
                              ),
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

  Future<void> _showSaleDialog({dynamic existingSale}) async {
    final copy = AppCopy.of(context);
    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController(text: '1');
    int? selectedProductId;
    int? priorProductId;
    var priorQty = 0.0;
    if (existingSale != null) {
      final items = await widget.repo.getSaleItems(existingSale.id);
      if (items.isNotEmpty) {
        selectedProductId = items.first.productId;
        priorProductId = items.first.productId;
        priorQty = items.first.qty;
        qtyCtrl.text = items.first.qty.toString();
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existingSale == null
                ? (copy.isEnglish ? 'Record sale' : 'Mag-record ng benta')
                : (copy.isEnglish ? 'Update sale' : 'I-update ang benta'),
          ),
          content: StreamBuilder(
            stream: widget.repo.watchProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              dynamic selectedProduct;
              if (selectedProductId != null) {
                for (final product in products) {
                  if (product.id == selectedProductId) {
                    selectedProduct = product;
                    break;
                  }
                }
              }
              return Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedProductId,
                       hint: Text(copy.isEnglish ? 'Choose a product' : 'Pumili ng produkto'),
                      items: products
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} (${p.unitType}) stock:${p.stockQty.toStringAsFixed(2)}',
                              ),
                            ),
                          )
                          .toList(),
                      validator: (v) =>
                           v == null ? (copy.isEnglish ? 'Product is required.' : 'Produkto ay required.') : null,
                      onChanged: (value) =>
                          setState(() => selectedProductId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: qtyCtrl,
                      decoration: InputDecoration(
                         labelText: selectedProduct == null
                             ? (copy.isEnglish ? 'Quantity / weight' : 'Dami / Timbang')
                             : (copy.isEnglish ? 'Quantity (${selectedProduct.unitType})' : 'Dami (${selectedProduct.unitType})'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (selectedProductId == null) {
                          return copy.isEnglish ? 'Choose a product first.' : 'Pumili muna ng produkto.';
                        }
                        final product = products.firstWhere(
                          (p) => p.id == selectedProductId,
                        );
                        final base = product.unitType == 'kg'
                              ? InputValidators.validateDecimalPositive(
                                  v ?? '',
                                  field: copy.isEnglish ? 'Weight' : 'Timbang',
                                )
                            : InputValidators.validateWholePositive(
                                v ?? '',
                                 field: 'Qty',
                              );
                        if (base != null) return base;
                        final q = double.tryParse(v ?? '') ?? 0;
                        var effectiveAvailable = product.stockQty;
                        if (existingSale != null &&
                            priorProductId != null &&
                            selectedProductId == priorProductId) {
                          effectiveAvailable = product.stockQty + priorQty;
                        }
                        if (q > effectiveAvailable) {
                           return copy.isEnglish ? 'Not allowed. Insufficient stock. Max: ' : 'Hindi pwede. Kulang stock. Max: '
                               '${effectiveAvailable.toStringAsFixed(2)}.';
                        }
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
               child: Text(copy.inventoryCancel),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedProductId == null) return;
                final products = await widget.repo.watchProducts().first;
                final product = products.firstWhere(
                  (p) => p.id == selectedProductId,
                );
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
               child: Text(copy.isEnglish ? 'Save sale' : 'I-save ang benta'),
            ),
          ],
        ),
      ),
    );
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
