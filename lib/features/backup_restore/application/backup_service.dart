import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/repositories/tinda_repository.dart';

class BackupService {
  BackupService(this.repo);

  final TindaRepository repo;

  Future<String> exportJsonFile() async {
    final payload = await repo.exportJsonBackup();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'tindatrack_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Future<Map<String, dynamic>?> pickAndReadJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    if (picked.bytes != null) {
      final text = utf8.decode(picked.bytes!);
      return jsonDecode(text) as Map<String, dynamic>;
    }
    if (picked.path != null) {
      final text = await File(picked.path!).readAsString();
      return jsonDecode(text) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, int>?> previewPickedJson() async {
    final payload = await pickAndReadJson();
    if (payload == null) return null;
    return repo.previewJsonBackup(payload);
  }

  Future<void> importPickedJson({required bool replaceAll}) async {
    final payload = await pickAndReadJson();
    if (payload == null) return;
    await repo.importJsonBackup(payload, replaceAll: replaceAll);
  }

  Future<String> exportDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final sourcePath = p.join(dir.path, 'tinda_track.sqlite');
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('Database file not found: $sourcePath');
    }
    final backupName = 'tindatrack_db_${DateTime.now().millisecondsSinceEpoch}.sqlite';
    final target = File(p.join(dir.path, backupName));
    await source.copy(target.path);
    return target.path;
  }

  Future<void> importDatabaseFile({required bool replaceAll}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sqlite', 'db'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final target = File(p.join(dir.path, 'tinda_track.sqlite'));
    if (!replaceAll) {
      throw Exception('Merge mode is not supported for raw DB import.');
    }
    final picked = result.files.first;
    if (picked.path != null) {
      await File(picked.path!).copy(target.path);
      return;
    }
    if (kIsWeb) {
      throw Exception('Raw DB import is not supported on web.');
    }
    final bytes = picked.bytes;
    if (bytes == null) return;
    await target.writeAsBytes(Uint8List.fromList(bytes));
  }
}
