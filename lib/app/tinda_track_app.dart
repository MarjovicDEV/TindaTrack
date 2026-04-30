import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/presentation/home_shell_page.dart';

class TindaTrackApp extends StatelessWidget {
  const TindaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TindaTrack',
      theme: AppTheme.lightTheme,
      home: const HomeShellPage(),
    );
  }
}
