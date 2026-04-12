import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Web file download helper — web implementation using package:web.
void downloadFileWeb(List<int> bytes, String fileName, {String mimeType = 'application/octet-stream'}) {
  final uint8Array = Uint8List.fromList(bytes).toJS;
  final blob = web.Blob([uint8Array].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
