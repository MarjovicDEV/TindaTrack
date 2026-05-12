import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../application/backup_service.dart';

class BackupRestoreSection extends StatefulWidget {
  const BackupRestoreSection({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<BackupRestoreSection> createState() => _BackupRestoreSectionState();
}

class _BackupRestoreSectionState extends State<BackupRestoreSection> {
  late final BackupService _backupService;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(widget.repo);
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.backupRestoreTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(copy.backupRestoreDescription),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: _exportJson,
                  child: Text(copy.exportJson),
                ),
                OutlinedButton(
                  onPressed: _importJsonDialog,
                  child: Text(copy.importJson),
                ),
                OutlinedButton(
                  onPressed: kIsWeb ? null : _exportDb,
                  child: Text(copy.exportDb),
                ),
                OutlinedButton(
                  onPressed: kIsWeb ? null : _importDbDialog,
                  child: Text(copy.importDb),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportJson() async {
    try {
      final path = await _backupService.exportJsonFile();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppCopy.of(context).backupJsonSaved(path))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _exportDb() async {
    try {
      final path = await _backupService.exportDatabaseFile();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppCopy.of(context).backupDbSaved(path))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _importJsonDialog() async {
    final mode = await _askMode();
    if (mode == null) return;
    try {
      await _backupService.importPickedJson(replaceAll: mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mode ? AppCopy.of(context).backupReplaceDone : AppCopy.of(context).backupMergeDone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _importDbDialog() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context).backupDbUnsupportedWeb)),
      );
      return;
    }

    final mode = await _askMode();
    if (mode == null) return;
    try {
      await _backupService.importDatabaseFile(replaceAll: mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppCopy.of(context).backupDbImportRestart)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<bool?> _askMode() {
    final copy = AppCopy.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppCopy.of(context).backupRestoreModeTitle),
        content: Text(AppCopy.of(context).backupReplaceWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(copy.mergeMode),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.replaceMode),
          ),
        ],
      ),
    );
  }
}
