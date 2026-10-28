import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Whether the paintings could be cleared without anyone deleting them:
/// true unless the browser promised to keep this site's storage (see
/// `IndexedDbStoreBackend`), as browsers may clear it when space runs low.
Future<bool> storageAtRisk() async {
  try {
    return !(await web.window.navigator.storage.persisted().toDart).toDart;
  } catch (_) {
    return true;
  }
}
