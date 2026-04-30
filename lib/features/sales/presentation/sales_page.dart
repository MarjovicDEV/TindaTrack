import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  int? _selectedProductId;
  final _qtyCtrl = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Sales', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: _selectedProductId == null ? null : _recordSimpleSale,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Record Sale'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder(
          stream: widget.repo.watchProducts(),
          builder: (context, snapshot) {
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Add inventory first before recording sales.'),
                ),
              );
            }
            return Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedProductId,
                    hint: const Text('Select product'),
                    items: products
                        .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (stock: ${p.stockQty})')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedProductId = value),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchSales(),
            builder: (context, snapshot) {
              final sales = snapshot.data ?? [];
              if (sales.isEmpty) {
                return const Center(child: Text('No sales recorded yet.'));
              }
              return ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final item = sales[index];
                  return Card(
                    child: ListTile(
                      title: Text('Sale #${item.id}'),
                      subtitle: Text(item.createdAt.toString()),
                      trailing: Text('PHP ${item.totalAmount.toStringAsFixed(2)}'),
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

  Future<void> _recordSimpleSale() async {
    final products = await widget.repo.watchProducts().first;
    final product = products.firstWhere((p) => p.id == _selectedProductId);
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0 || qty > product.stockQty) return;

    await widget.repo.recordSale([
      SaleItemsCompanion(
        saleId: const Value(0),
        productId: Value(product.id),
        qty: Value(qty),
        unitPrice: Value(product.price),
      ),
    ]);
  }
}
