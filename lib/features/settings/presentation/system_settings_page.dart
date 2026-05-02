import 'package:flutter/material.dart';

import '../../../core/currency/currency_controller.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/resources/app_copy.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/theme/theme_picker_sheet.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../backup_restore/presentation/backup_restore_section.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({
    required this.themeController,
    required this.localeController,
    required this.currencyController,
    required this.repo,
    super.key,
  });

  final ThemeModeController themeController;
  final LocaleController localeController;
  final CurrencyController currencyController;
  final TindaRepository repo;

  static const _currencies = ['PHP', 'USD', 'EUR'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppCopy.settingsSystemSection)),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text(AppCopy.themeMenuTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showThemeModePickerSheet(context: context, controller: themeController),
          ),
          ListenableBuilder(
            listenable: localeController,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    leading: Icon(Icons.language_outlined),
                    title: Text(AppCopy.settingsLanguage),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedButton<Locale>(
                      segments: const [
                        ButtonSegment(value: Locale('fil'), label: Text('Filipino')),
                        ButtonSegment(value: Locale('en'), label: Text('English')),
                      ],
                      selected: {localeController.locale},
                      onSelectionChanged: (s) => localeController.setLocale(s.first),
                    ),
                  ),
                ],
              );
            },
          ),
          ListenableBuilder(
            listenable: currencyController,
            builder: (context, _) {
              return ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text(AppCopy.settingsCurrency),
                subtitle: Text(currencyController.code),
                trailing: DropdownButton<String>(
                  value: _currencies.contains(currencyController.code)
                      ? currencyController.code
                      : 'PHP',
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) currencyController.setCode(v);
                  },
                ),
              );
            },
          ),
          BackupRestoreSection(repo: repo),
        ],
      ),
    );
  }
}
