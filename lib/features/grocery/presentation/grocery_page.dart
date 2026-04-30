import 'package:flutter/material.dart';

import '../../../data/repositories/tinda_repository.dart';

class GroceryPage extends StatelessWidget {
  const GroceryPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Grocery List', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton(
              onPressed: () => _showAddItem(context),
              child: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: repo.watchGroceryItems(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Center(child: Text('No grocery items yet.'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return CheckboxListTile(
                    title: Text(item.name),
                    subtitle: Text('Qty: ${item.qty}'),
                    value: item.isDone,
                    onChanged: (value) => repo.toggleGrocery(item.id, value ?? false),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddItem(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Grocery Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              if (name.isEmpty || qty <= 0) return;
              await repo.addGroceryItem(name, qty: qty);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
