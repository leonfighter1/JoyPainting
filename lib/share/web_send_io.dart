import 'dart:typed_data';

import 'web_send_result.dart';

export 'web_send_result.dart';

/// Only the web uses these; apps share through the system share sheet.
void downloadInBrowser(Uint8List bytes, String name, String mimeType) =>
    throw UnsupportedError('Only for the web');


Future<WebSendResult> sendFromBrowser(Uint8List bytes,
        {required String name,
        required String mimeType,
        required String subject,
        required String body}) =>
    throw UnsupportedError('Only for the web');
