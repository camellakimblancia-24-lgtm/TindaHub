import 'dart:convert';

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

  testWidgets('shows selected image bytes on home and product details', (
    WidgetTester tester,
  ) async {
    final product = StoreProduct(
      id: 'local-image',
      name: 'Local product',
      price: 25,
      stock: 5,
      imageBytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            products: [product],
            customers: const [],
            dailySales: 0,
            ownerName: 'Test owner',
            onOpenTab: (_) {},
            onAddSale: () {},
            onAddProduct: (_) {},
          ),
        ),
      ),
    );

    final memoryImages = find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is MemoryImage,
    );
    expect(memoryImages, findsOneWidget);

    await tester.tap(find.text('Local product'));
    await tester.pumpAndSettle();
    expect(memoryImages, findsNWidgets(2));
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

  testWidgets('shows an add image action in the product form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();

    final addButton = find.byTooltip('Add product');
    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      expect(find.text('Add product'), findsOneWidget);
      expect(find.byTooltip('Look up product'), findsOneWidget);
      expect(find.text('Add image'), findsOneWidget);
      return;
    }

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Add product'), findsOneWidget);
    expect(find.byTooltip('Look up product'), findsOneWidget);
    expect(find.text('Add image'), findsOneWidget);
  });

  testWidgets('searches customers and marks long-standing utang', (
    WidgetTester tester,
  ) async {
    final oldCustomer = StoreCustomer(
      id: 'old',
      name: 'Aling Nena',
      balance: 125,
      history: [
        LedgerEntry(
          description: 'Unpaid purchase',
          amount: 125,
          date: DateTime.now().subtract(const Duration(days: 31)),
          isPayment: false,
        ),
      ],
    );
    final recentCustomer = StoreCustomer(
      id: 'recent',
      name: 'Mang Jose',
      balance: 60,
      history: [
        LedgerEntry(
          description: 'Recent purchase',
          amount: 60,
          date: DateTime.now().subtract(const Duration(days: 2)),
          isPayment: false,
        ),
      ],
    );
    final recentlyOwedCustomer = StoreCustomer(
      id: 'recently-owed',
      name: 'Aling Rosa',
      balance: 60,
      history: [
        LedgerEntry(
          description: 'Old purchase',
          amount: 100,
          date: DateTime.now().subtract(const Duration(days: 45)),
          isPayment: false,
        ),
        LedgerEntry(
          description: 'Old balance paid',
          amount: 100,
          date: DateTime.now().subtract(const Duration(days: 5)),
          isPayment: true,
        ),
        LedgerEntry(
          description: 'Recent purchase',
          amount: 60,
          date: DateTime.now().subtract(const Duration(days: 1)),
          isPayment: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UtangLedgerScreen(
            customers: [oldCustomer, recentCustomer, recentlyOwedCustomer],
            onPayment: (customer, amount) {},
          ),
        ),
      ),
    );

    expect(find.text('Unpaid for 30+ days'), findsOneWidget);
    expect(find.text('Outstanding balance'), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'nena');
    await tester.pumpAndSettle();
    expect(find.text('Aling Nena'), findsOneWidget);
    expect(find.text('Mang Jose'), findsNothing);
  });

  testWidgets('saves a partial payment and updates customer balance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.tap(find.text('Utang').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aling Nena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '25');
    await tester.tap(find.text('Save payment'));
    await tester.pumpAndSettle();

    expect(find.text('₱100.00'), findsOneWidget);
    expect(find.text('−₱25.00'), findsOneWidget);
  });

  testWidgets('suggests previous customers for an utang sale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.tap(find.text('Add Sale'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.tap(find.text('Utang'));
    await tester.pumpAndSettle();

    final customerField = find.byType(TextField).last;
    await tester.ensureVisible(customerField);
    await tester.showKeyboard(customerField);
    await tester.pumpAndSettle();
    expect(find.text('Aling Nena'), findsOneWidget);
    expect(find.text('Mang Jose'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Aling');
    await tester.pumpAndSettle();

    expect(find.text('Aling Nena'), findsOneWidget);
    await tester.tap(find.text('Aling Nena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save sale'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Utang').last);
    await tester.pumpAndSettle();
    expect(find.text('Aling Nena'), findsOneWidget);
    expect(find.text('₱183.00'), findsOneWidget);
  });

  testWidgets('calculates change when cash exceeds the utang balance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.tap(find.text('Utang').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aling Nena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '200');
    await tester.pumpAndSettle();
    expect(find.text('Change due: ₱75.00'), findsOneWidget);

    await tester.tap(find.text('Save payment'));
    await tester.pumpAndSettle();

    expect(find.text('₱0.00'), findsOneWidget);
    expect(find.text('−₱125.00'), findsOneWidget);
    expect(find.textContaining('Cash ₱200.00 · Change ₱75.00'), findsOneWidget);
  });

  testWidgets('shows weekly, monthly, and best-selling summaries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TindaHubApp());

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Best-selling products'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Best-selling products'), findsOneWidget);
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
    expect(find.text('₱908.00'), findsNWidgets(4));
    await tester.scrollUntilVisible(
      find.text('Rice (1 kg)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rice (1 kg)'), findsOneWidget);
    expect(find.text('1 sold'), findsOneWidget);
  });
}
