import 'package:flutter/widgets.dart';

class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;

  /// Legacy fixed padding; prefer [pageOf] for responsive layouts.
  static const EdgeInsets page = EdgeInsets.all(md);
  static const EdgeInsets card = EdgeInsets.all(md);

  /// Horizontal and vertical page padding scales with viewport width.
  static EdgeInsets pageOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontal = w >= 1200 ? xl : (w >= 600 ? lg : md);
    final vertical = w >= 600 ? md : sm;
    return EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical);
  }
}
