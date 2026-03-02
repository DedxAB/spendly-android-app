import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/app/spendly_app.dart';

void main() {
  testWidgets('Spendly app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpendlyApp()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(Scaffold), findsWidgets);
  });
}
