import 'package:flutter/material.dart';

import '../../../data/repositories/tinda_repository.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Imbentaryo', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showAddProductDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Magdagdag ng produkto'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: repo.watchProducts(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('Wala pang produkto.'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final low = item.stockQty <= item.lowStockThreshold;
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'Presyo: PHP ${item.price.toStringAsFixed(2)}  |  Stock: ${item.stockQty}',
                      ),
                      trailing: low
                          ? const Chip(
                              avatar: Icon(Icons.warning_amber_outlined, size: 16),
                              label: Text('Mababa'),
                            )
                          : const Chip(label: Text('Ayos')),
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

  Future<void> _showAddProductDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '1');
    final thresholdCtrl = TextEditingController(text: '5');

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Magdagdag ng produkto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Pangalan')),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Presyo'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: thresholdCtrl,
                decoration: const InputDecoration(labelText: 'Babala sa mababang stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0;
              final stock = int.tryParse(stockCtrl.text) ?? 0;
              final threshold = int.tryParse(thresholdCtrl.text) ?? 5;
              if (name.isEmpty || price <= 0 || stock < 0) return;
              await repo.addProduct(
                name: name,
                price: price,
                stockQty: stock,
                threshold: threshold,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('I-save'),
          ),
        ],
      ),
    );
  }
}
