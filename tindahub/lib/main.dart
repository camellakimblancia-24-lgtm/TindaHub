import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'open_food_facts.dart';

void main() {
  runApp(const TindaHubApp());
}

const _green = Color(0xFF527453);
const _lightGreen = Color(0xFFEAF1E4);
const _orange = Color(0xFFF38B2D);
const _cream = Color(0xFFFFF9F1);
const _ink = Color(0xFF292D24);

String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';

String _productMetadata(StoreProduct product) => [
  if (product.brand != null) product.brand!,
  if (product.size != null) product.size!,
].join(' • ');

Widget _buildProductImage(
  String? imageSource, {
  Uint8List? imageBytes,
  required Widget fallback,
  double width = 56,
  double height = 56,
  BoxFit fit = BoxFit.contain,
}) {
  if (imageBytes != null) {
    return Image.memory(
      imageBytes,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  if (imageSource == null || imageSource.trim().isEmpty) {
    return fallback;
  }

  final uri = Uri.tryParse(imageSource);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return Image.network(
      imageSource,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  return fallback;
}

class StoreProduct {
  StoreProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
    this.brand,
    this.size,
    this.imageUrl,
    this.imageBytes,
  });

  final String id;
  String name;
  double price;
  int stock;
  String? barcode;
  String? brand;
  String? size;
  String? imageUrl;
  Uint8List? imageBytes;
}

class LedgerEntry {
  const LedgerEntry({
    required this.description,
    required this.amount,
    required this.date,
    required this.isPayment,
    this.cashReceived,
    this.changeGiven,
  });

  final String description;
  final double amount;
  final DateTime date;
  final bool isPayment;
  final double? cashReceived;
  final double? changeGiven;
}

class PaymentRecord {
  const PaymentRecord({
    required this.cashReceived,
    required this.amountApplied,
    required this.changeGiven,
  });

  final double cashReceived;
  final double amountApplied;
  final double changeGiven;
}

class StoreCustomer {
  StoreCustomer({
    required this.id,
    required this.name,
    this.balance = 0,
    List<LedgerEntry>? history,
  }) : history = history ?? <LedgerEntry>[];

  final String id;
  final String name;
  double balance;
  final List<LedgerEntry> history;
}

class SaleLine {
  const SaleLine({required this.product, required this.quantity});

  final StoreProduct product;
  final int quantity;

  double get total => product.price * quantity;
}

class ProductSaleItem {
  const ProductSaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final int quantity;
}

class SaleRecord {
  const SaleRecord({
    required this.total,
    required this.date,
    required this.isPaid,
    this.customerName,
    this.items = const [],
  });

  final double total;
  final DateTime date;
  final bool isPaid;
  final String? customerName;
  final List<ProductSaleItem> items;
}

class TindaHubApp extends StatefulWidget {
  const TindaHubApp({super.key});

  @override
  State<TindaHubApp> createState() => _TindaHubAppState();
}

class _TindaHubAppState extends State<TindaHubApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _products = <StoreProduct>[
    StoreProduct(
      id: '1',
      name: 'Rice (1 kg)',
      price: 58,
      stock: 12,
      imageUrl:
          'https://images.openfoodfacts.org/images/products/324/883/296/7611/front_fr.140.400.jpg',
    ),
    StoreProduct(
      id: '2',
      name: 'Instant noodles',
      price: 15,
      stock: 4,
      imageUrl:
          'https://images.openfoodfacts.org/images/products/880/107/311/6467/front_de.166.400.jpg',
    ),
    StoreProduct(
      id: '3',
      name: 'Canned sardines',
      price: 27,
      stock: 8,
      imageUrl:
          'https://images.openfoodfacts.org/images/products/500/017/105/3015/front_en.10.400.jpg',
    ),
    StoreProduct(
      id: '4',
      name: 'Bottled water',
      price: 20,
      stock: 2,
      imageUrl:
          'https://images.openfoodfacts.org/images/products/002/259/200/7014/front_en.37.400.jpg',
    ),
  ];
  final _customers = <StoreCustomer>[
    StoreCustomer(
      id: '1',
      name: 'Aling Nena',
      balance: 125,
      history: [
        LedgerEntry(
          description: 'Previous purchase',
          amount: 125,
          date: DateTime.now().subtract(const Duration(days: 2)),
          isPayment: false,
        ),
      ],
    ),
    StoreCustomer(
      id: '2',
      name: 'Mang Jose',
      balance: 60,
      history: [
        LedgerEntry(
          description: 'Previous purchase',
          amount: 60,
          date: DateTime.now().subtract(const Duration(days: 1)),
          isPayment: false,
        ),
      ],
    ),
  ];
  final _sales = <SaleRecord>[
    SaleRecord(total: 850, date: DateTime.now(), isPaid: true),
  ];
  int _selectedTab = 0;
  String _ownerName = 'Store owner';

  void _saveSale(List<SaleLine> lines, bool isPaid, String? customerName) {
    final total = lines.fold<double>(0, (sum, line) => sum + line.total);
    setState(() {
      for (final line in lines) {
        final product = _products.firstWhere(
          (item) => item.id == line.product.id,
        );
        product.stock -= line.quantity;
      }
      _sales.add(
        SaleRecord(
          total: total,
          date: DateTime.now(),
          isPaid: isPaid,
          customerName: customerName,
          items: List.unmodifiable(
            lines.map(
              (line) => ProductSaleItem(
                productId: line.product.id,
                productName: line.product.name,
                quantity: line.quantity,
              ),
            ),
          ),
        ),
      );
      if (!isPaid && customerName != null) {
        final normalizedName = customerName.trim();
        final existing = _customers.where(
          (customer) =>
              customer.name.toLowerCase() == normalizedName.toLowerCase(),
        );
        if (existing.isEmpty) {
          _customers.add(
            StoreCustomer(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: normalizedName,
              balance: total,
            ),
          );
        } else {
          existing.first.balance += total;
        }
        final customer = _customers.firstWhere(
          (item) => item.name.toLowerCase() == normalizedName.toLowerCase(),
        );
        customer.history.add(
          LedgerEntry(
            description:
                'Credit sale: ${lines.map((line) {
                  final metadata = _productMetadata(line.product);
                  return '${line.product.name}${metadata.isEmpty ? '' : ' ($metadata)'} × ${line.quantity}';
                }).join(', ')}',
            amount: total,
            date: DateTime.now(),
            isPayment: false,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final todaySales = _sales
        .where((sale) => _sameDay(sale.date, DateTime.now()))
        .fold<double>(0, (total, sale) => total + sale.total);
    final pages = <Widget>[
      DashboardScreen(
        products: _products,
        customers: _customers,
        dailySales: todaySales,
        ownerName: _ownerName,
        onOpenTab: (index) => setState(() => _selectedTab = index),
        onAddSale: () => _openSale(),
        onAddProduct: (product) => _openSale(selectedProductId: product.id),
      ),
      ProductListScreen(
        products: _products,
        onSave: (product) {
          setState(() {
            final index = _products.indexWhere((item) => item.id == product.id);
            if (index == -1) {
              _products.add(product);
            } else {
              _products[index]
                ..name = product.name
                ..price = product.price
                ..stock = product.stock
                ..barcode = product.barcode
                ..brand = product.brand
                ..size = product.size
                ..imageUrl = product.imageUrl
                ..imageBytes = product.imageBytes;
            }
          });
        },
        onDelete: (product) => setState(() => _products.remove(product)),
      ),
      UtangLedgerScreen(
        customers: _customers,
        onPayment: (customer, payment) {
          setState(() {
            customer.balance = (customer.balance - payment.amountApplied).clamp(
              0,
              double.infinity,
            );
            customer.history.add(
              LedgerEntry(
                description: 'Payment received',
                amount: payment.amountApplied,
                date: DateTime.now(),
                isPayment: true,
                cashReceived: payment.cashReceived,
                changeGiven: payment.changeGiven,
              ),
            );
          });
        },
      ),
      DailySummaryScreen(sales: _sales),
    ];
    final titles = ['TindaHub', 'Products', 'Utang Ledger', 'Daily Summary'];

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'TindaHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _orange),
        scaffoldBackgroundColor: _cream,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: const Color(0x140E2410),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 185, 237, 139),
          foregroundColor: _ink,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFE8D1),
          elevation: 8,
          height: 72,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _orange : const Color(0xFF888A80),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? _orange : _green);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFECEDE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _orange, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            minimumSize: const Size(48, 48),
          ),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            titles[_selectedTab],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                tooltip: 'Edit owner name',
                onPressed: _editOwnerName,
                style: IconButton.styleFrom(
                  backgroundColor: _lightGreen,
                  foregroundColor: _green,
                ),
                icon: Text(
                  _ownerName.isEmpty ? 'T' : _ownerName[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(index: _selectedTab, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) =>
              setState(() => _selectedTab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Utang',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Summary',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSale({String? selectedProductId}) async {
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (context) => AddSaleScreen(
          products: _products,
          customers: _customers,
          onSave: _saveSale,
          selectedProductId: selectedProductId,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editOwnerName() async {
    final updatedName = await showDialog<String>(
      context: _navigatorKey.currentContext!,
      builder: (dialogContext) => _EditOwnerNameDialog(name: _ownerName),
    );
    if (updatedName != null && mounted) {
      setState(() => _ownerName = updatedName);
    }
  }
}

class _EditOwnerNameDialog extends StatefulWidget {
  const _EditOwnerNameDialog({required this.name});

  final String name;

  @override
  State<_EditOwnerNameDialog> createState() => _EditOwnerNameDialogState();
}

class _EditOwnerNameDialogState extends State<_EditOwnerNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Store owner name'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Your name',
          prefixIcon: Icon(Icons.person_outline),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter your name' : null,
        onFieldSubmitted: (_) => _save(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save name')),
    ],
  );

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

DateTime? _oldestUnpaidCreditDate(StoreCustomer customer) {
  if (customer.balance <= 0) return null;

  final entries = [...customer.history]
    ..sort((first, second) => first.date.compareTo(second.date));
  final unpaidDates = <DateTime>[];
  final unpaidAmounts = <double>[];

  for (final entry in entries) {
    if (!entry.isPayment) {
      unpaidDates.add(entry.date);
      unpaidAmounts.add(entry.amount);
      continue;
    }

    var paymentRemaining = entry.amount;
    while (paymentRemaining > 0 && unpaidAmounts.isNotEmpty) {
      if (paymentRemaining >= unpaidAmounts.first) {
        paymentRemaining -= unpaidAmounts.removeAt(0);
        unpaidDates.removeAt(0);
      } else {
        unpaidAmounts[0] -= paymentRemaining;
        paymentRemaining = 0;
      }
    }
  }

  return unpaidDates.isEmpty ? null : unpaidDates.first;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.products,
    required this.customers,
    required this.dailySales,
    required this.ownerName,
    required this.onOpenTab,
    required this.onAddSale,
    required this.onAddProduct,
    super.key,
  });

  final List<StoreProduct> products;
  final List<StoreCustomer> customers;
  final double dailySales;
  final String ownerName;
  final ValueChanged<int> onOpenTab;
  final VoidCallback onAddSale;
  final ValueChanged<StoreProduct> onAddProduct;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  final _categories = const ['All', 'Staples', 'Snacks', 'Drinks', 'Canned'];
  String _selectedCategory = 'All';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = widget.products
        .where((product) => product.stock <= 5)
        .toList();
    final totalUtang = widget.customers.fold<double>(
      0,
      (sum, customer) => sum + customer.balance,
    );
    final filteredProducts = widget.products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        _query.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'All' ||
          _productCategory(product) == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                  children: [
                    const TextSpan(text: 'Welcome, '),
                    TextSpan(text: '${widget.ownerName}!'),
                  ],
                ),
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.storefront_rounded, color: _green),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _HomeStatCard(
                label: 'TODAY’S SALES',
                value: _peso(widget.dailySales),
                icon: Icons.trending_up_rounded,
                tint: const Color(0xFFFFEBD8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HomeStatCard(
                label: 'Total utang',
                value: _peso(totalUtang),
                icon: Icons.menu_book_rounded,
                tint: _lightGreen,
                onTap: () => widget.onOpenTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search your products...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => widget.onOpenTab(1),
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(Icons.tune_rounded, color: _green),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final selected = category == _selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      selectedColor: _orange,
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : _ink,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: widget.onAddSale,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add Sale'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Popular items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ),
            TextButton(
              onPressed: () => widget.onOpenTab(1),
              child: const Text('See all'),
            ),
          ],
        ),
        if (filteredProducts.isEmpty)
          const _EmptyCard(message: 'No matching products in your shop.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length > 6
                ? 6
                : filteredProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 228,
            ),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _BrowseProductCard(
                product: product,
                onOpen: () => _showProductDetails(context, product),
                onAdd: () => widget.onAddProduct(product),
              );
            },
          ),
        const SizedBox(height: 22),
        Text(
          'Low-stock alerts',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (lowStock.isEmpty)
          const _EmptyCard(message: 'All products are well stocked.')
        else
          ...lowStock
              .take(3)
              .map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: _ProductThumbnail(
                        product: product,
                        fallbackIcon: Icons.warning_amber_rounded,
                        backgroundColor: const Color(0xFFFFF0EC),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${product.stock} left in stock'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.onOpenTab(1),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Future<void> _showProductDetails(
    BuildContext context,
    StoreProduct product,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductDetailsSheet(
        product: product,
        onAdd: () {
          Navigator.pop(context);
          widget.onAddProduct(product);
        },
      ),
    );
  }
}

String _productCategory(StoreProduct product) {
  final name = product.name.toLowerCase();
  if (name.contains('rice') ||
      name.contains('sugar') ||
      name.contains('flour')) {
    return 'Staples';
  }
  if (name.contains('noodle') ||
      name.contains('chip') ||
      name.contains('snack')) {
    return 'Snacks';
  }
  if (name.contains('water') ||
      name.contains('juice') ||
      name.contains('drink') ||
      name.contains('soda')) {
    return 'Drinks';
  }
  if (name.contains('canned') ||
      name.contains('sardine') ||
      name.contains('tuna')) {
    return 'Canned';
  }
  return 'All';
}

class _BrowseProductCard extends StatelessWidget {
  const _BrowseProductCard({
    required this.product,
    required this.onOpen,
    required this.onAdd,
  });

  final StoreProduct product;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final background = product.stock <= 5
        ? const Color(0xFFFFE4D9)
        : const Color(0xFFEAF1E4);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: background,
                    child:
                        product.imageUrl == null && product.imageBytes == null
                        ? Center(
                            child: Text(
                              _productEmoji(product),
                              style: const TextStyle(fontSize: 62),
                            ),
                          )
                        : _buildProductImage(
                            product.imageUrl,
                            imageBytes: product.imageBytes,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            fallback: Center(
                              child: Text(
                                _productEmoji(product),
                                style: const TextStyle(fontSize: 62),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.stock} left',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 8, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _peso(product.price),
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: _orange,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAdd,
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _productEmoji(StoreProduct product) {
  final name = product.name.toLowerCase();
  if (name.contains('rice')) return '🍚';
  if (name.contains('noodle')) return '🍜';
  if (name.contains('sardine') || name.contains('canned')) return '🥫';
  if (name.contains('water')) return '💧';
  if (name.contains('fruit')) return '🍊';
  return '🛍️';
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _green, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF77796F),
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProductDetailsSheet extends StatelessWidget {
  const _ProductDetailsSheet({required this.product, required this.onAdd});

  final StoreProduct product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D8CE),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: 210,
              color: _lightGreen,
              child: product.imageUrl == null && product.imageBytes == null
                  ? Center(
                      child: Text(
                        _productEmoji(product),
                        style: const TextStyle(fontSize: 90),
                      ),
                    )
                  : _buildProductImage(
                      product.imageUrl,
                      imageBytes: product.imageBytes,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      fallback: Center(
                        child: Text(
                          _productEmoji(product),
                          style: const TextStyle(fontSize: 90),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          if (_productMetadata(product).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _productMetadata(product),
              style: const TextStyle(color: Color(0xFF77796F)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _peso(product.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                '${product.stock} in stock',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: product.stock <= 0 ? null : onAdd,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Record a sale'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SalesOverviewCard extends StatelessWidget {
  const _SalesOverviewCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: _lightGreen,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.trending_up, color: _green, size: 18),
            SizedBox(width: 8),
            Text(
              "TODAY'S SALES",
              style: TextStyle(
                color: _green,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _peso(amount),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Total value of sales recorded today',
          style: TextStyle(color: Color(0xFF65675F)),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE9E6DE)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: _green, size: 20),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      ),
    ),
  );
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    required this.products,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final List<StoreProduct> products;
  final ValueChanged<StoreProduct> onSave;
  final ValueChanged<StoreProduct> onDelete;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({
    required this.product,
    required this.fallbackIcon,
    this.backgroundColor = _lightGreen,
  });

  final StoreProduct product;
  final IconData fallbackIcon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(fallbackIcon, color: _green),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _buildProductImage(
        product.imageUrl,
        imageBytes: product.imageBytes,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        fallback: fallback,
      ),
    );
  }
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your stock',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    Text(
                      '${widget.products.length} items in your shop',
                      style: const TextStyle(color: Color(0xFF7A7D72)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBD8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: _orange),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: FilledButton.styleFrom(backgroundColor: _orange),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final isLow = product.stock <= 5;
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        leading: _ProductThumbnail(
                          product: product,
                          fallbackIcon: Icons.inventory_2_outlined,
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        subtitle: Text(
                          [
                            '${_peso(product.price)}  •  ${product.stock} in stock',
                            if (_productMetadata(product).isNotEmpty)
                              _productMetadata(product),
                          ].join('  •  '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editProduct(product);
                            } else {
                              _confirmDelete(product);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                        isThreeLine:
                            product.brand != null || product.size != null,
                        dense: false,
                        subtitleTextStyle: TextStyle(
                          color: isLow
                              ? const Color(0xFFB94A32)
                              : Colors.black54,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _addProduct() async {
    final result = await showDialog<StoreProduct>(
      context: context,
      builder: (context) => const ProductFormDialog(),
    );
    if (result != null) widget.onSave(result);
  }

  Future<void> _editProduct(StoreProduct product) async {
    final result = await showDialog<StoreProduct>(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );
    if (result != null) widget.onSave(result);
  }

  Future<void> _confirmDelete(StoreProduct product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove ${product.name} from your product list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) widget.onDelete(product);
  }
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({this.product, super.key});

  final StoreProduct? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _barcodeController;
  late final OpenFoodFactsService _openFoodFactsService;
  String? _brand;
  String? _size;
  String? _imageUrl;
  Uint8List? _pickedImageBytes;
  String? _lookupError;
  bool _lookupCanRetry = false;
  bool _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    _openFoodFactsService = OpenFoodFactsService();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
    _barcodeController = TextEditingController(
      text: widget.product?.barcode ?? '',
    );
    _brand = widget.product?.brand;
    _size = widget.product?.size;
    _imageUrl = widget.product?.imageUrl;
    _pickedImageBytes = widget.product?.imageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _openFoodFactsService.close();
    super.dispose();
  }

  Future<void> _pickProductImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    setState(() {
      _pickedImageBytes = bytes;
      _imageUrl = null;
    });
  }

  void _setLookupError(String message, {bool canRetry = false}) {
    setState(() {
      _lookupError = message;
      _lookupCanRetry = canRetry;
    });
  }

  Future<void> _lookupProduct() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      _setLookupError('Enter a barcode to look up.');
      return;
    }

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
      _lookupCanRetry = false;
      _brand = null;
      _size = null;
      _imageUrl = null;
      _pickedImageBytes = null;
    });
    try {
      final product = await _openFoodFactsService.lookupByBarcode(barcode);
      if (!mounted) return;
      if (product == null) {
        _setLookupError(
          'No product found. Enter the product details manually.',
        );
        return;
      }
      setState(() {
        _nameController.text = product.name;
        _barcodeController.text = product.barcode;
        _brand = product.brand;
        _size = product.size;
        _imageUrl = product.imageUrl;
        _pickedImageBytes = null;
      });
    } on InvalidBarcodeException catch (error) {
      if (!mounted) return;
      _setLookupError(error.message);
    } on LookupOfflineException {
      if (!mounted) return;
      _setLookupError(
        'No internet connection. Check your connection and retry, '
        'or enter the details manually.',
        canRetry: true,
      );
    } on LookupServerException {
      if (!mounted) return;
      _setLookupError(
        'The product database is having problems. Retry, '
        'or enter the details manually.',
        canRetry: true,
      );
    } on FormatException {
      if (!mounted) return;
      _setLookupError(
        'The product data could not be read. Enter the details manually.',
      );
    } catch (_) {
      if (!mounted) return;
      _setLookupError(
        'Something went wrong. Retry, or enter the details manually.',
        canRetry: true,
      );
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        Expanded(
          child: Text(widget.product == null ? 'Add product' : 'Edit product'),
        ),
        IconButton.filled(
          tooltip: 'Look up product',
          onPressed: _isLookingUp ? null : _lookupProduct,
          icon: _isLookingUp
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
        ),
      ],
    ),
    scrollable: true,
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _barcodeController,
            decoration: const InputDecoration(
              labelText: 'Barcode',
              hintText: 'Scan or enter barcode',
            ),
            keyboardType: TextInputType.number,
          ),
          if (_lookupError != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lookupError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (_lookupCanRetry)
                    TextButton.icon(
                      onPressed: _isLookingUp ? null : _lookupProduct,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ],
          if (_brand != null ||
              _size != null ||
              _imageUrl != null ||
              _pickedImageBytes != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (_imageUrl != null || _pickedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildProductImage(
                      _imageUrl,
                      imageBytes: _pickedImageBytes,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      fallback: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                Expanded(
                  child: Text([_brand, _size].whereType<String>().join(' • ')),
                ),
              ],
            ),
          ],
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Product name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a product name'
                : null,
          ),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Price (₱)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              return price == null || price <= 0
                  ? 'Enter a price greater than 0'
                  : null;
            },
          ),
          TextFormField(
            controller: _stockController,
            decoration: const InputDecoration(labelText: 'Quantity in stock'),
            keyboardType: TextInputType.number,
            validator: (value) {
              final stock = int.tryParse(value ?? '');
              return stock == null || stock < 0
                  ? 'Enter a valid quantity'
                  : null;
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickProductImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add image'),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            StoreProduct(
              id:
                  widget.product?.id ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
              name: _nameController.text.trim(),
              price: double.parse(_priceController.text),
              stock: int.parse(_stockController.text),
              barcode: _barcodeController.text.trim().isEmpty
                  ? null
                  : _barcodeController.text.trim(),
              brand: _brand,
              size: _size,
              imageUrl: _imageUrl,
              imageBytes: _pickedImageBytes,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({
    required this.products,
    required this.customers,
    required this.onSave,
    this.selectedProductId,
    super.key,
  });

  final List<StoreProduct> products;
  final List<StoreCustomer> customers;
  final void Function(List<SaleLine>, bool, String?) onSave;
  final String? selectedProductId;

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _quantities = <String, int>{};
  final _customerController = TextEditingController();
  final _customerFocusNode = FocusNode();
  bool _isPaid = true;

  @override
  void initState() {
    super.initState();
    final selectedId = widget.selectedProductId;
    if (selectedId != null &&
        widget.products.any(
          (product) => product.id == selectedId && product.stock > 0,
        )) {
      _quantities[selectedId] = 1;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _customerFocusNode.dispose();
    super.dispose();
  }

  List<SaleLine> get _lines => widget.products
      .where((product) => (_quantities[product.id] ?? 0) > 0)
      .map(
        (product) =>
            SaleLine(product: product, quantity: _quantities[product.id]!),
      )
      .toList();

  double get _total => _lines.fold<double>(0, (sum, line) => sum + line.total);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Sale')),
    body: widget.products.isEmpty
        ? const Center(
            child: Text(
              'Add products to your inventory before recording a sale.',
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Select items',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.products.map(_productRow),
                    const SizedBox(height: 20),
                    Text(
                      'Payment type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Paid'),
                          icon: Icon(Icons.payments_outlined),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Utang'),
                          icon: Icon(Icons.menu_book_outlined),
                        ),
                      ],
                      selected: {_isPaid},
                      onSelectionChanged: (selection) =>
                          setState(() => _isPaid = selection.first),
                    ),
                    if (!_isPaid) ...[
                      const SizedBox(height: 12),
                      RawAutocomplete<StoreCustomer>(
                        textEditingController: _customerController,
                        focusNode: _customerFocusNode,
                        displayStringForOption: (customer) => customer.name,
                        optionsBuilder: (value) {
                          final query = value.text.trim().toLowerCase();
                          return widget.customers.where(
                            (customer) =>
                                customer.name.toLowerCase().contains(query),
                          );
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmitted) =>
                                TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer name',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => onSubmitted(),
                                ),
                        optionsViewBuilder: (context, onSelected, options) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final customer = options.elementAt(index);
                                  return ListTile(
                                    title: Text(customer.name),
                                    subtitle: customer.balance > 0
                                        ? Text(
                                            'Balance: ${_peso(customer.balance)}',
                                          )
                                        : null,
                                    onTap: () => onSelected(customer),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 12,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.black54,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              _peso(_total),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check),
                        label: const Text('Save sale'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          minimumSize: const Size(130, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );

  Widget _productRow(StoreProduct product) {
    final quantity = _quantities[product.id] ?? 0;
    final unavailable = product.stock <= 0;
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            _ProductThumbnail(
              product: product,
              fallbackIcon: Icons.shopping_basket_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_peso(product.price)}  •  ${product.stock} available',
                  ),
                  if (_productMetadata(product).isNotEmpty)
                    Text(
                      _productMetadata(product),
                      style: const TextStyle(color: Colors.black54),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: quantity == 0
                  ? null
                  : () =>
                        setState(() => _quantities[product.id] = quantity - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: unavailable || quantity >= product.stock
                  ? null
                  : () =>
                        setState(() => _quantities[product.id] = quantity + 1),
              icon: const Icon(Icons.add_circle_outline, color: _green),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final lines = _lines;
    final customerName = _customerController.text.trim();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one product.')),
      );
      return;
    }
    if (!_isPaid && customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the customer name for an utang sale.'),
        ),
      );
      return;
    }
    widget.onSave(lines, _isPaid, _isPaid ? null : customerName);
    Navigator.pop(context);
  }
}

class UtangLedgerScreen extends StatefulWidget {
  const UtangLedgerScreen({
    required this.customers,
    required this.onPayment,
    super.key,
  });

  final List<StoreCustomer> customers;
  final void Function(StoreCustomer, PaymentRecord) onPayment;

  @override
  State<UtangLedgerScreen> createState() => _UtangLedgerScreenState();
}

class _UtangLedgerScreenState extends State<UtangLedgerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final total = widget.customers.fold<double>(
      0,
      (sum, customer) => sum + customer.balance,
    );
    final filteredCustomers = widget.customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _lightGreen,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL OUTSTANDING',
                style: TextStyle(color: _green, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              Text(
                _peso(total),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.customers.where((customer) => customer.balance > 0).length} customers with a balance',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search customers',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: filteredCustomers.isEmpty
              ? Center(
                  child: Text(
                    widget.customers.isEmpty
                        ? 'No customer balances yet.'
                        : 'No customers found.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredCustomers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    final oldestCredit = _oldestUnpaidCreditDate(customer);
                    final isOverdue =
                        customer.balance > 0 &&
                        oldestCredit != null &&
                        DateTime.now().difference(oldestCredit).inDays >= 30;
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFFF3DF),
                          child: Text(
                            customer.name.isEmpty
                                ? '?'
                                : customer.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isOverdue
                              ? 'Unpaid for 30+ days'
                              : 'Outstanding balance',
                          style: TextStyle(
                            color: isOverdue
                                ? const Color(0xFFB94A32)
                                : Colors.black54,
                            fontWeight: isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _peso(customer.balance),
                              style: TextStyle(
                                color: customer.balance > 0
                                    ? const Color(0xFFB94A32)
                                    : _green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailScreen(
                              customer: customer,
                              onPayment: widget.onPayment,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    required this.customer,
    required this.onPayment,
    super.key,
  });

  final StoreCustomer customer;
  final void Function(StoreCustomer, PaymentRecord) onPayment;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(customer.name)),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT BALANCE',
                  style: TextStyle(color: _green, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  _peso(customer.balance),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Account activity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: customer.history.isEmpty
                ? const _EmptyCard(message: 'No account activity yet.')
                : ListView.separated(
                    itemCount: customer.history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry =
                          customer.history[customer.history.length - index - 1];
                      final date = entry.date;
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: entry.isPayment
                                ? _lightGreen
                                : const Color(0xFFFFF3DF),
                            child: Icon(
                              entry.isPayment
                                  ? Icons.payments_outlined
                                  : Icons.shopping_bag_outlined,
                              color: _green,
                            ),
                          ),
                          title: Text(entry.description),
                          subtitle: Text(
                            [
                              '${date.day}/${date.month}/${date.year} · '
                                  '${date.hour.toString().padLeft(2, '0')}:'
                                  '${date.minute.toString().padLeft(2, '0')}',
                              if (entry.cashReceived != null)
                                'Cash ${_peso(entry.cashReceived!)} · '
                                    'Change ${_peso(entry.changeGiven ?? 0)}',
                            ].join(' · '),
                          ),
                          trailing: Text(
                            '${entry.isPayment ? '−' : '+'}${_peso(entry.amount)}',
                            style: TextStyle(
                              color: entry.isPayment
                                  ? _green
                                  : const Color(0xFFB94A32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: customer.balance <= 0
                ? null
                : () => _recordPayment(context),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Record payment'),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _recordPayment(BuildContext context) async {
    final payment = await showDialog<PaymentRecord>(
      context: context,
      builder: (context) => _RecordPaymentDialog(balance: customer.balance),
    );
    if (payment != null) onPayment(customer, payment);
  }
}

class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({required this.balance});

  final double balance;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record payment'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Cash received',
            prefixText: '₱ ',
            helperText: 'Balance: ${_peso(widget.balance)}',
          ),
        ),
        const SizedBox(height: 8),
        Text('Change due: ${_peso(_changeDue)}'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save payment')),
    ],
  );

  double get _changeDue {
    final cashReceived = double.tryParse(_controller.text) ?? 0;
    return cashReceived > widget.balance ? cashReceived - widget.balance : 0;
  }

  void _save() {
    final cashReceived = double.tryParse(_controller.text);
    if (cashReceived == null || cashReceived <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a cash amount greater than 0.')),
      );
      return;
    }

    final amountApplied = cashReceived > widget.balance
        ? widget.balance
        : cashReceived;
    Navigator.pop(
      context,
      PaymentRecord(
        cashReceived: cashReceived,
        amountApplied: amountApplied,
        changeGiven: cashReceived - amountApplied,
      ),
    );
  }
}

class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({required this.sales, super.key});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final startOfNextWeek = startOfWeek.add(const Duration(days: 7));
    final startOfMonth = DateTime(now.year, now.month);
    final startOfNextMonth = DateTime(now.year, now.month + 1);
    final today = sales.where((sale) => _sameDay(sale.date, now)).toList();
    final total = today.fold<double>(0, (sum, sale) => sum + sale.total);
    final paid = today
        .where((sale) => sale.isPaid)
        .fold<double>(0, (sum, sale) => sum + sale.total);
    final credit = total - paid;
    final weekTotal = sales
        .where(
          (sale) =>
              !sale.date.isBefore(startOfWeek) &&
              sale.date.isBefore(startOfNextWeek),
        )
        .fold<double>(0, (sum, sale) => sum + sale.total);
    final monthTotal = sales
        .where(
          (sale) =>
              !sale.date.isBefore(startOfMonth) &&
              sale.date.isBefore(startOfNextMonth),
        )
        .fold<double>(0, (sum, sale) => sum + sale.total);
    final soldQuantities = <String, int>{};
    final productNames = <String, String>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        soldQuantities.update(
          item.productId,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
        productNames[item.productId] = item.productName;
      }
    }
    final bestSellers = soldQuantities.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        _SalesOverviewCard(amount: total),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.payments_outlined,
                label: 'Paid sales',
                value: _peso(paid),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.menu_book_outlined,
                label: 'Utang sales',
                value: _peso(credit),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.date_range_outlined,
                label: 'This week',
                value: _peso(weekTotal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.calendar_month_outlined,
                label: 'This month',
                value: _peso(monthTotal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Sales this week',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _WeeklySalesChart(sales: sales, today: now),
        const SizedBox(height: 24),
        Text(
          'Best-selling products',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (bestSellers.isEmpty)
          const _EmptyCard(message: 'No product sales recorded yet.')
        else
          ...bestSellers
              .take(5)
              .map(
                (entry) => Card(
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: _lightGreen,
                      child: Icon(Icons.trending_up, color: _green),
                    ),
                    title: Text(productNames[entry.key]!),
                    trailing: Text(
                      '${entry.value} sold',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 24),
        Text(
          'Today’s transactions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (today.isEmpty)
          const _EmptyCard(message: 'No sales recorded today.')
        else
          ...today.reversed.map(
            (sale) => Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: sale.isPaid
                      ? _lightGreen
                      : const Color(0xFFFFF3DF),
                  child: Icon(
                    sale.isPaid ? Icons.check : Icons.menu_book,
                    color: _green,
                  ),
                ),
                title: Text(
                  sale.isPaid
                      ? 'Paid sale'
                      : 'Utang sale${sale.customerName == null ? '' : ' · ${sale.customerName}'}',
                ),
                subtitle: Text(
                  '${sale.date.hour.toString().padLeft(2, '0')}:${sale.date.minute.toString().padLeft(2, '0')}',
                ),
                trailing: Text(
                  _peso(sale.total),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeeklySalesChart extends StatelessWidget {
  const _WeeklySalesChart({required this.sales, required this.today});

  final List<SaleRecord> sales;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - 6 + index),
    );
    final totals = days
        .map(
          (day) => sales
              .where((sale) => _sameDay(sale.date, day))
              .fold<double>(0, (sum, sale) => sum + sale.total),
        )
        .toList();
    final maxTotal = totals.fold<double>(
      0,
      (max, total) => total > max ? total : max,
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE9E6DE)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              final total = totals[index];
              final barHeight = maxTotal == 0 ? 4.0 : 56 * total / maxTotal;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 18,
                      height: barHeight.clamp(4, 56),
                      decoration: BoxDecoration(
                        color: total == 0 ? _lightGreen : _orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      const [
                        'M',
                        'T',
                        'W',
                        'T',
                        'F',
                        'S',
                        'S',
                      ][days[index].weekday - 1],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF77796F),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}