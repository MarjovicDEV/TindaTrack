import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_scaffold.dart';
import '../../../core/resources/app_copy.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../expenses/presentation/expenses_page.dart';
import '../../grocery/presentation/grocery_page.dart';
import '../../inventory/presentation/inventory_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../../sales/presentation/sales_page.dart';
import '../../utang/presentation/utang_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({required this.themeController, super.key});

  final ThemeModeController themeController;

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
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
      appBarActions: [
        IconButton(
          tooltip: AppCopy.themeMenuTitle,
          icon: const Icon(Icons.brightness_6_outlined),
          onPressed: _showThemePicker,
        ),
      ],
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: AppCopy.navDashboard,
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          label: AppCopy.navInventory,
        ),
        NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          label: AppCopy.navSales,
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: AppCopy.navUtang,
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: AppCopy.navExpenses,
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          label: AppCopy.navGrocery,
        ),
      ],
      body: pages[_index],
    );
  }

  Future<void> _showThemePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: widget.themeController,
          builder: (context, _) {
            final current = widget.themeController.themeMode;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(title: Text(AppCopy.themeMenuTitle)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text(AppCopy.themeSystem),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text(AppCopy.themeDark),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text(AppCopy.themeLight),
                        ),
                      ],
                      selected: {current},
                      onSelectionChanged: (selection) {
                        _selectTheme(selection.first);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectTheme(ThemeMode? mode) async {
    if (mode == null) {
      return;
    }

    await widget.themeController.setThemeMode(mode);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
