import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/dashboard/presentation/home_shell_page.dart';

class TindaTrackApp extends StatefulWidget {
  const TindaTrackApp({this.themeController, super.key});

  final ThemeModeController? themeController;

  @override
  State<TindaTrackApp> createState() => _TindaTrackAppState();
}

class _TindaTrackAppState extends State<TindaTrackApp> {
  late final ThemeModeController _themeController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.themeController == null;
    _themeController = widget.themeController ?? ThemeModeController();
    _themeController.load();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TindaTrack',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeController.themeMode,
        home: HomeShellPage(themeController: _themeController),
      ),
    );
  }
}
