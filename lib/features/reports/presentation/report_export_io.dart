import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MissingPluginException, MethodChannel, PlatformException;
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/tinda_track_export.dart';

const MethodChannel _exportChannel = MethodChannel('com.tinda_track.tinda_track/export');

String _fileStamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

/// PNG raster from capture → high-quality JPEG (smaller files; better for “Photos” UX on some devices).
Uint8List _capturePngToJpeg(Uint8List pngBytes) {
  final decoded = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
  if (decoded == null) {
    throw StateError('Could not decode captured image');
  }
  return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
}

/// Writes [jpegBytes] to [TindaTrackExport.documentsFolderName] (same tree as PDF). Pure [dart:io] — no gal channel.
Future<String> _saveJpegToTindaTrackDocuments(Uint8List jpegBytes, String fileName) async {
  final folderName = TindaTrackExport.documentsFolderName;
  late final Directory root;

  if (Platform.isIOS || Platform.isMacOS) {
    final appDoc = await getApplicationDocumentsDirectory();
    root = Directory(p.join(appDoc.path, folderName));
  } else if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext == null) {
      final appDoc = await getApplicationDocumentsDirectory();
      root = Directory(p.join(appDoc.path, folderName));
    } else {
      root = Directory(p.join(ext.path, 'Documents', folderName));
    }
  } else {
    final downloads = await getDownloadsDirectory();
    root = downloads != null
        ? Directory(p.join(downloads.path, folderName))
        : Directory(
            p.join((await getApplicationDocumentsDirectory()).path, folderName),
          );
  }

  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  final path = p.join(root.path, fileName);
  await File(path).writeAsBytes(jpegBytes);
  return path;
}

/// Raster export: accepts **PNG** bytes from [RepaintBoundary], stores as **JPEG** (gallery via [Gal] when available).
///
/// If [Gal] is not registered ([MissingPluginException]) or fails unexpectedly, saves **.jpg** under app
/// [TindaTrackExport.documentsFolderName] (Files / Documents) — no plugin channel required.
Future<String> writeReportPngBytes(List<int> bytes) async {
  final jpeg = _capturePngToJpeg(Uint8List.fromList(bytes));
  final baseName = 'tindatrack_${_fileStamp()}';
  final album = TindaTrackExport.galleryAlbumName;
  final docFileName = '$baseName.jpg';

  Future<String> fallbackToDisk(String reason) async {
    final path = await _saveJpegToTindaTrackDocuments(jpeg, docFileName);
    return '$reason — $path';
  }

  if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
    try {
      final ok = await Gal.requestAccess(toAlbum: true);
      if (!ok) {
        throw StateError(
          'Photos / gallery access denied. Allow access when prompted, or enable it in system Settings for this app.',
        );
      }

      Future<void> saveJpegBytes() => Gal.putImageBytes(jpeg, album: album, name: baseName);

      Future<void> saveFromTempFile() async {
        final tmpDir = await getTemporaryDirectory();
        final tmpFile = File(p.join(tmpDir.path, '$baseName.jpg'));
        await tmpFile.writeAsBytes(jpeg);
        try {
          await Gal.putImage(tmpFile.path, album: album);
        } finally {
          if (await tmpFile.exists()) await tmpFile.delete();
        }
      }

      try {
        await saveJpegBytes();
      } on GalException {
        await saveFromTempFile();
      }

      return Platform.isIOS || Platform.isMacOS
          ? 'Photos · $album · $baseName.jpg'
          : 'Gallery · $album · $baseName.jpg';
    } on MissingPluginException {
      return fallbackToDisk(
        'Gallery plugin unavailable (rebuild app after flutter pub get). Saved JPG to TindaTrack folder',
      );
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) rethrow;
      return fallbackToDisk('Gallery save failed (${e.type.message}). Saved JPG to TindaTrack folder');
    }
  }

  if (Platform.isWindows || Platform.isLinux) {
    try {
      final ok = await Gal.requestAccess(toAlbum: false);
      if (!ok) {
        throw StateError('Pictures permission denied');
      }
      await Gal.putImageBytes(jpeg, album: album, name: baseName);
      return 'Pictures · $album · $baseName.jpg';
    } on MissingPluginException {
      final path = await _saveJpegToTindaTrackDocuments(jpeg, docFileName);
      return path;
    } catch (_) {
      final path = await _saveJpegToTindaTrackDocuments(jpeg, docFileName);
      return path;
    }
  }

  final dir = await getTemporaryDirectory();
  final path = p.join(dir.path, docFileName);
  await File(path).writeAsBytes(jpeg);
  return path;
}

/// PDF → app Documents (iOS/macOS/desktop) or **public** Documents/Downloads on Android (visible in Files).
Future<String> writeReportPdfBytes(List<int> bytes) async {
  final fileName = 'tindatrack_${_fileStamp()}.pdf';
  final folderName = TindaTrackExport.documentsFolderName;

  if (Platform.isAndroid) {
    final tmpDir = await getTemporaryDirectory();
    final tmpFile = File(p.join(tmpDir.path, fileName));
    await tmpFile.writeAsBytes(bytes);
    try {
      final saved = await _exportChannel.invokeMethod<String>(
        'savePdfToPublicDocuments',
        <String, dynamic>{
          'tempPath': tmpFile.path,
          'displayName': fileName,
          'folderName': folderName,
        },
      );
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } on MissingPluginException {
      // e.g. unit tests without embedding
    } on PlatformException {
      // Native save failed; fall back below.
    } finally {
      if (await tmpFile.exists()) await tmpFile.delete();
    }
  }

  return _writeReportPdfBytesAppScoped(bytes, fileName, folderName);
}

Future<String> _writeReportPdfBytesAppScoped(
  List<int> bytes,
  String fileName,
  String folderName,
) async {
  late final Directory root;

  if (Platform.isIOS || Platform.isMacOS) {
    final appDoc = await getApplicationDocumentsDirectory();
    root = Directory(p.join(appDoc.path, folderName));
  } else if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext == null) {
      final appDoc = await getApplicationDocumentsDirectory();
      root = Directory(p.join(appDoc.path, folderName));
    } else {
      root = Directory(p.join(ext.path, 'Documents', folderName));
    }
  } else {
    final downloads = await getDownloadsDirectory();
    root = downloads != null
        ? Directory(p.join(downloads.path, folderName))
        : Directory(
            p.join((await getApplicationDocumentsDirectory()).path, folderName),
          );
  }

  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  final path = p.join(root.path, fileName);
  await File(path).writeAsBytes(bytes);
  return path;
}
