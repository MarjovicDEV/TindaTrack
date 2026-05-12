import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/resources/app_copy.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  static const _kLow = 'notif_low_stock';
  static const _kGrocery = 'notif_grocery';

  bool _lowStock = true;
  bool _grocery = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _lowStock = p.getBool(_kLow) ?? true;
      _grocery = p.getBool(_kGrocery) ?? true;
    });
  }

  Future<void> _ensureNotificationPermission() async {
    final s = await Permission.notification.status;
    if (s.isGranted) return;
    await Permission.notification.request();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(copy.notificationSettingsTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(copy.notificationLowStock),
            value: _lowStock,
            onChanged: (v) async {
              if (v) await _ensureNotificationPermission();
              setState(() => _lowStock = v);
              final p = await SharedPreferences.getInstance();
              await p.setBool(_kLow, v);
            },
          ),
          SwitchListTile(
            title: Text(copy.notificationGroceryReminder),
            value: _grocery,
            onChanged: (v) async {
              if (v) await _ensureNotificationPermission();
              setState(() => _grocery = v);
              final p = await SharedPreferences.getInstance();
              await p.setBool(_kGrocery, v);
            },
          ),
        ],
      ),
    );
  }
}
