import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_scaffold.dart';
import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../expenses/presentation/expenses_page.dart';
import '../../grocery/presentation/grocery_page.dart';
import '../../inventory/presentation/inventory_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../../sales/presentation/sales_page.dart';
import '../../utang/presentation/utang_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  late final AppDatabase _db;
  late final TindaRepository _repo;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    _repo = TindaRepository(_db);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ReportsPage(repo: _repo),
      InventoryPage(repo: _repo),
      SalesPage(repo: _repo),
      UtangPage(repo: _repo),
      ExpensesPage(repo: _repo),
      GroceryPage(repo: _repo),
    ];

    return AdaptiveScaffold(
      title: AppCopy.appTitle,
      titleWidget: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children: [
            const TextSpan(text: 'Tinda'),
            TextSpan(
              text: 'Track',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: AppCopy.navDashboard),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: AppCopy.navInventory),
        NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), label: AppCopy.navSales),
        NavigationDestination(icon: Icon(Icons.people_outline), label: AppCopy.navUtang),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: AppCopy.navExpenses),
        NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: AppCopy.navGrocery),
      ],
      body: Padding(
        padding: AppSpacing.page,
        child: pages[_index],
      ),
    );
  }
}
