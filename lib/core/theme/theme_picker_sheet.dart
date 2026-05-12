import 'package:flutter/material.dart';

import '../resources/app_copy.dart';
import 'theme_mode_controller.dart';

Future<void> showThemeModePickerSheet({
  required BuildContext context,
  required ThemeModeController controller,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final copy = AppCopy.of(context);
          final current = controller.themeMode;

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text(copy.themeSheetTitle)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text(copy.themeSystem),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text(copy.themeDark),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text(copy.themeLight),
                      ),
                    ],
                    selected: {current},
                    onSelectionChanged: (selection) async {
                      final mode = selection.first;
                      await controller.setThemeMode(mode);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
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
