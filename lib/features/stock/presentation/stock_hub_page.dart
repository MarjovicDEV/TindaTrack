import 'package:flutter/material.dart';

import '../../../core/resources/app_copy.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../grocery/presentation/grocery_page.dart';
import '../../inventory/presentation/inventory_page.dart';

class StockHubPage extends StatefulWidget {
  const StockHubPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<StockHubPage> createState() => _StockHubPageState();
}

class _StockHubPageState extends State<StockHubPage> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(value: 0, label: Text(copy.navInventory)),
              ButtonSegment<int>(value: 1, label: Text(copy.navGrocery)),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => setState(() => _segment = s.first),
          ),
        ),
        Expanded(
          child: _segment == 0
              ? InventoryPage(repo: widget.repo)
              : GroceryPage(repo: widget.repo),
        ),
      ],
    );
  }
}
