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
          final current = controller.themeMode;

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
