import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeher/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeHerApp());

    expect(find.text('SHTREE KAVACH'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });
}

