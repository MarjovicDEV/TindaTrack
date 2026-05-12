import 'package:flutter/material.dart';

import '../../../core/currency/currency_controller.dart';
import '../../../core/layout/adaptive_scaffold.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/resources/app_copy.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../expenses/presentation/expenses_page.dart';
import '../../history/presentation/history_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../../sales/presentation/sales_page.dart';
import '../../settings/presentation/settings_hub_page.dart';
import '../../stock/presentation/stock_hub_page.dart';
import '../../utang/presentation/utang_page.dart';
import 'home_overview_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    required this.themeController,
    required this.localeController,
    required this.currencyController,
    super.key,
  });

  final ThemeModeController themeController;
  final LocaleController localeController;
  final CurrencyController currencyController;

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

  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsHubPage(
          themeController: widget.themeController,
          localeController: widget.localeController,
          currencyController: widget.currencyController,
          repo: _repo,
        ),
      ),
    );
  }

  Future<void> _showSpeedDial() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final copy = AppCopy.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.point_of_sale_outlined),
                title: Text(copy.speedDialBenta),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => SalesPage(repo: _repo)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(copy.speedDialUtang),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => UtangPage(repo: _repo)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(copy.speedDialGastos),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => ExpensesPage(repo: _repo)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.currencyController.code;
    final pages = <Widget>[
      HomeOverviewPage(repo: _repo, currencyCode: code),
      StockHubPage(repo: _repo),
      HistoryPage(repo: _repo),
      ReportsPage(repo: _repo, currencyCode: code),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge([widget.currencyController, widget.localeController]),
      builder: (context, _) {
        final copy = AppCopy.of(context);
        final scheme = Theme.of(context).colorScheme;

        Widget navIcon({required int index, required IconData icon, required IconData selectedIcon}) {
          final selected = _index == index;
          return IconButton(
            tooltip: _labelForIndex(copy, index),
            icon: Icon(selected ? selectedIcon : icon),
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            onPressed: () => setState(() => _index = index),
          );
        }

        final narrowBar = BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(child: navIcon(index: 0, icon: Icons.home_outlined, selectedIcon: Icons.home)),
                Expanded(
                  child: navIcon(
                    index: 1,
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2,
                  ),
                ),
                const SizedBox(width: 72),
                Expanded(
                  child: navIcon(
                    index: 2,
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                  ),
                ),
                Expanded(
                  child: navIcon(
                    index: 3,
                    icon: Icons.assessment_outlined,
                    selectedIcon: Icons.assessment,
                  ),
                ),
              ],
            ),
          ),
        );
        return AdaptiveScaffold(
          title: copy.appTitle,
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
              tooltip: copy.settingsTooltip,
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettings,
            ),
          ],
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: copy.navHome),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: copy.navStock),
            NavigationDestination(icon: Icon(Icons.history_outlined), label: copy.navHistory),
            NavigationDestination(icon: Icon(Icons.assessment_outlined), label: copy.navReports),
          ],
          narrowBottomBar: narrowBar,
          floatingActionButton: FloatingActionButton(
            tooltip: copy.speedDialTitle,
            onPressed: _showSpeedDial,
            child: const Icon(Icons.add),
          ),
          body: pages[_index],
        );
      },
    );
  }

  String _labelForIndex(AppCopy copy, int index) {
    return switch (index) {
      0 => copy.navHome,
      1 => copy.navStock,
      2 => copy.navHistory,
      _ => copy.navReports,
    };
  }
}
