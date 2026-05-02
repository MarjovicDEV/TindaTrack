import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> writeReportPngBytes(List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/tindatrack_ulat.png';
  await File(path).writeAsBytes(bytes);
  return path;
}

Future<String> writeReportPdfBytes(List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/tindatrack_ulat.pdf';
  await File(path).writeAsBytes(bytes);
  return path;
}
