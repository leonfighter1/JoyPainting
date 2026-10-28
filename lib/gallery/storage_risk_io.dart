/// Whether the paintings could be cleared without anyone deleting them.
/// The apps keep them in their own folder: not at risk.
Future<bool> storageAtRisk() async => false;
