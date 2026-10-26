import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindahub/main.dart';

void main() {
  testWidgets('shows the TindaHub dashboard and store overview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    expect(find.text('TindaHub'), findsOneWidget);
    expect(find.text('TODAY’S SALES'), findsOneWidget);
    expect(find.text('Low-stock alerts'), findsOneWidget);
    expect(find.text('Instant noodles'), findsOneWidget);
  });

  testWidgets('records a sale and updates inventory and daily summary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.tap(find.text('Add Sale'));
    await tester.pumpAndSettle();
    expect(find.text('Select items'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.tap(find.text('Save sale'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('11 in stock'), findsOneWidget);

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(find.text('₱908.00'), findsNWidgets(2));
  });
}
