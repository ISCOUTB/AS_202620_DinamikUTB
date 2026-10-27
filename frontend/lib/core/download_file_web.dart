import 'dart:typed_data';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool downloadFile(Uint8List bytes, String filename, String mediaType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mediaType),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
  return true;
}
