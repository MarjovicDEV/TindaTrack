import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/repositories/tinda_repository.dart';

class UtangPage extends StatefulWidget {
  const UtangPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<UtangPage> createState() => _UtangPageState();
}

class _UtangPageState extends State<UtangPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Utang Manager', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton(
              onPressed: () => _showAddCustomer(context),
              child: const Text('Add Customer'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchCustomers(),
            builder: (context, snapshot) {
              final customers = snapshot.data ?? [];
              if (customers.isEmpty) return const Center(child: Text('No customers yet.'));
              return ListView.builder(
                itemCount: customers.length,
                itemBuilder: (_, index) {
                  final customer = customers[index];
                  return Card(
                    child: ListTile(
                      title: Text(customer.name),
                      subtitle: const Text('Manage entries and payments'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showAddEntry(context, customer.id),
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

  Future<void> _showAddCustomer(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Customer'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Customer name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await widget.repo.addCustomer(ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEntry(BuildContext context, int customerId) async {
    final amountCtrl = TextEditingController();
    var isPayment = false;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Utang Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(isPayment ? 'Payment' : 'New Utang'),
                subtitle: Text(
                  isPayment ? 'This reduces balance' : 'This increases balance',
                ),
                value: isPayment,
                onChanged: (v) => setState(() => isPayment = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) return;
                await widget.repo.addUtang(
                  customerId: customerId,
                  amount: amount,
                  isPayment: isPayment,
                  note: isPayment ? 'Payment received' : 'Utang recorded',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved ${formatCurrency(amount)} entry')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
