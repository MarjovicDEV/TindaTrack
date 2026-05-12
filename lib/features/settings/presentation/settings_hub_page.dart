import 'package:flutter/material.dart';

import '../../../core/currency/currency_controller.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/resources/app_copy.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../data/repositories/tinda_repository.dart';
import 'notification_settings_page.dart';
import 'profile_settings_page.dart';
import 'system_settings_page.dart';

class SettingsHubPage extends StatelessWidget {
  const SettingsHubPage({
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

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(copy.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(copy.settingsNotificationsSection),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(copy.settingsProfileSection),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const ProfileSettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: Text(copy.settingsSystemSection),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SystemSettingsPage(
                    themeController: themeController,
                    localeController: localeController,
                    currencyController: currencyController,
                    repo: repo,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
