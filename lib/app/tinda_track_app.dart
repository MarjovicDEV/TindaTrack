import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/currency/currency_controller.dart';
import '../core/locale/locale_controller.dart';
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
  late final LocaleController _localeController;
  late final CurrencyController _currencyController;
  late final bool _ownsTheme;

  @override
  void initState() {
    super.initState();
    _ownsTheme = widget.themeController == null;
    _themeController = widget.themeController ?? ThemeModeController();
    _localeController = LocaleController();
    _currencyController = CurrencyController();
    _themeController.load();
    _localeController.load();
    _currencyController.load();
  }

  @override
  void dispose() {
    if (_ownsTheme) {
      _themeController.dispose();
    }
    _localeController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_themeController, _localeController, _currencyController]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TindaTrack',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeController.themeMode,
        locale: _localeController.locale,
        supportedLocales: const [Locale('en'), Locale('fil')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomeShellPage(
          themeController: _themeController,
          localeController: _localeController,
          currencyController: _currencyController,
        ),
      ),
    );
  }
}
