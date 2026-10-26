import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindahub/main.dart';

void main() {
  testWidgets('shows the grocery-style home and store overview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    expect(find.text('TindaHub'), findsOneWidget);
    expect(find.text('Popular items'), findsOneWidget);
    expect(find.text('Instant noodles'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Low-stock alerts'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('TODAY’S SALES'), findsOneWidget);
    expect(find.text('Low-stock alerts'), findsOneWidget);
  });

  testWidgets('opens a product detail and preselects it for a sale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.ensureVisible(find.text('Instant noodles').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instant noodles').first);
    await tester.pumpAndSettle();
    expect(find.text('Record a sale'), findsOneWidget);

    await tester.tap(find.text('Record a sale'));
    await tester.pumpAndSettle();
    expect(find.text('Select items'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('updates the store owner name from the profile button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.tap(find.byTooltip('Edit owner name'));
    await tester.pumpAndSettle();
    expect(find.text('Store owner name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Camella');
    await tester.tap(find.text('Save name'));
    await tester.pumpAndSettle();

    expect(find.text('Camella 👋'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
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
