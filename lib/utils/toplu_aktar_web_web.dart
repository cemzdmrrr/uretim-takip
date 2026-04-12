import 'dart:async';
import 'dart:js_interop';
import 'package:excel/excel.dart';
import 'package:web/web.dart' as web;

Future<void> pickExcelFile(Future<void> Function(List<Map<String, dynamic>> rows) onImport) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.xlsx,.xls';
  input.click();

  final completer = Completer<void>();
  input.onChange.listen((_) => completer.complete());
  await completer.future;

  final files = input.files;
  if (files == null || files.length == 0) return;

  final file = files.item(0)!;
  final arrayBuffer = await file.arrayBuffer().toDart;
  final bytes = arrayBuffer.toDart.asUint8List();
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables[excel.tables.keys.first];
  if (sheet == null) throw Exception('Excel sayfası bulunamadı');

  final headers = <String>[];
  final data = <Map<String, dynamic>>[];

  for (var row in sheet.rows) {
    if (headers.isEmpty) {
      for (var cell in row) {
        headers.add(cell?.value?.toString() ?? '');
      }
      continue;
    }
    if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;
    final map = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      map[headers[i]] = row[i]?.value;
    }
    if (map.isNotEmpty && (map['marka']?.toString().isNotEmpty ?? false) && (map['item_no']?.toString().isNotEmpty ?? false)) {
      data.add(map);
    }
  }
  await onImport(data);
}
