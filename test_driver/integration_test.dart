import 'package:integration_test/integration_test_driver.dart';

/// Runs an integration test on a device and writes what it reports (frame
/// timings) to build/integration_response_data.json.
Future<void> main() => integrationDriver();
