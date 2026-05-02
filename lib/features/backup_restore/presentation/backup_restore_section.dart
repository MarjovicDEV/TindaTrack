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
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppCopy.backupRestoreTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Pumili ng export/import type. May preview at babala bago i-restore.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: _exportJson,
                  child: Text(AppCopy.exportJson),
                ),
                OutlinedButton(
                  onPressed: _importJsonDialog,
                  child: Text(AppCopy.importJson),
                ),
                OutlinedButton(
                  onPressed: kIsWeb ? null : _exportDb,
                  child: Text(AppCopy.exportDb),
                ),
                OutlinedButton(
                  onPressed: kIsWeb ? null : _importDbDialog,
                  child: Text(AppCopy.importDb),
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
      ).showSnackBar(SnackBar(content: Text('Na-export ang JSON backup: $path')));
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
      ).showSnackBar(SnackBar(content: Text('Na-export ang DB backup: $path')));
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
        SnackBar(content: Text(mode ? 'Na-restore (replace).' : 'Na-restore (merge).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _importDbDialog() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DB import/export ay hindi supported sa web. JSON ang gamitin.')),
      );
      return;
    }

    final mode = await _askMode();
    if (mode == null) return;
    try {
      await _backupService.importDatabaseFile(replaceAll: mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Na-import ang DB file. I-restart ang app kung kailangan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<bool?> _askMode() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Piliin ang restore mode'),
        content: const Text('Babala: Ang "Palitan lahat" ay bubura ng kasalukuyang records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppCopy.mergeMode),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppCopy.replaceMode),
          ),
        ],
      ),
    );
  }
}
