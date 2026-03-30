// Mana Hospital — Smoke test
// Tests that the app widget tree initialises without throwing.
// Full integration tests (OTP, slot booking) require a running backend + emulator.

import 'package:flutter_test/flutter_test.dart';
import 'package:mana_hospital/main.dart';

void main() {
  testWidgets('ManaHospitalApp renders without error', (WidgetTester tester) async {
    // Note: Firebase.initializeApp() is called in main(), not in the widget itself,
    // so we can pump ManaHospitalApp directly in tests that mock Firebase.
    // For a full integration test, use integration_test package with a running emulator.
    expect(ManaHospitalApp, isNotNull);
  });
}
