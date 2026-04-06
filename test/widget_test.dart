import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streetbeat/app.dart';

void main() {
  testWidgets('StreetbeatApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const StreetbeatApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
