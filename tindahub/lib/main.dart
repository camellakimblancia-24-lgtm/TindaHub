import 'package:flutter/material.dart';

void main() {
  runApp(const TindaHubApp());
}

const _green = Color(0xFF176B45);
const _lightGreen = Color(0xFFEAF5EE);

String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';

class StoreProduct {
  StoreProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  final String id;
  String name;
  double price;
  int stock;
}

class LedgerEntry {
  const LedgerEntry({
    required this.description,
    required this.amount,
    required this.date,
    required this.isPayment,
  });

  final String description;
  final double amount;
  final DateTime date;
  final bool isPayment;
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

class SaleRecord {
  const SaleRecord({
    required this.total,
    required this.date,
    required this.isPaid,
    this.customerName,
  });

  final double total;
  final DateTime date;
  final bool isPaid;
  final String? customerName;
}

class TindaHubApp extends StatefulWidget {
  const TindaHubApp({super.key});

  @override
  State<TindaHubApp> createState() => _TindaHubAppState();
}

class _TindaHubAppState extends State<TindaHubApp> {
  final _products = <StoreProduct>[
    StoreProduct(id: '1', name: 'Rice (1 kg)', price: 58, stock: 12),
    StoreProduct(id: '2', name: 'Instant noodles', price: 15, stock: 4),
    StoreProduct(id: '3', name: 'Canned sardines', price: 27, stock: 8),
    StoreProduct(id: '4', name: 'Bottled water', price: 20, stock: 2),
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
            description: 'Credit sale',
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
        onOpenTab: (index) => setState(() => _selectedTab = index),
        onAddSale: _openSale,
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
                ..stock = product.stock;
            }
          });
        },
        onDelete: (product) => setState(() => _products.remove(product)),
      ),
      UtangLedgerScreen(
        customers: _customers,
        onPayment: (customer, amount) {
          setState(() {
            customer.balance = (customer.balance - amount).clamp(
              0,
              double.infinity,
            );
            customer.history.add(
              LedgerEntry(
                description: 'Payment received',
                amount: amount,
                date: DateTime.now(),
                isPayment: true,
              ),
            );
          });
        },
      ),
      DailySummaryScreen(sales: _sales),
    ];
    final titles = ['TindaHub', 'Products', 'Utang Ledger', 'Daily Summary'];

    return MaterialApp(
      title: 'TindaHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
        scaffoldBackgroundColor: const Color(0xFFF7F9F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9F7),
          foregroundColor: Color(0xFF183329),
          centerTitle: false,
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
            if (_selectedTab == 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor: _lightGreen,
                  child: const Icon(Icons.storefront, color: _green),
                ),
              ),
          ],
        ),
        body: IndexedStack(index: _selectedTab, children: pages),
        floatingActionButton: _selectedTab == 0
            ? FloatingActionButton.extended(
                onPressed: _openSale,
                backgroundColor: _green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add Sale'),
              )
            : null,
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

  Future<void> _openSale() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            AddSaleScreen(products: _products, onSave: _saveSale),
      ),
    );
    if (mounted) setState(() {});
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.products,
    required this.customers,
    required this.dailySales,
    required this.onOpenTab,
    required this.onAddSale,
    super.key,
  });

  final List<StoreProduct> products;
  final List<StoreCustomer> customers;
  final double dailySales;
  final ValueChanged<int> onOpenTab;
  final VoidCallback onAddSale;

  @override
  Widget build(BuildContext context) {
    final lowStock = products.where((product) => product.stock <= 5).toList();
    final totalUtang = customers.fold<double>(
      0,
      (sum, customer) => sum + customer.balance,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text(
          'Good day, Store Owner!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Here’s how your store is doing today.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _SalesOverviewCard(amount: dailySales),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                value: '${products.length}',
                tint: const Color(0xFFEAF1FF),
                onTap: () => onOpenTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.people_outline,
                label: 'Total utang',
                value: _peso(totalUtang),
                tint: const Color(0xFFFFF3DF),
                onTap: () => onOpenTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low-stock alerts',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => onOpenTab(1),
              child: const Text('View all'),
            ),
          ],
        ),
        if (lowStock.isEmpty)
          const _EmptyCard(message: 'All products are well stocked.')
        else
          ...lowStock
              .take(3)
              .map(
                (product) => Card(
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF0EC),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB94A32),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${product.stock} left in stock'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onOpenTab(1),
                  ),
                ),
              ),
        const SizedBox(height: 20),
        Text(
          'Quick actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.add_shopping_cart,
                label: 'Record a sale',
                onTap: onAddSale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.menu_book,
                label: 'View utang',
                onTap: () => onOpenTab(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SalesOverviewCard extends StatelessWidget {
  const _SalesOverviewCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(colors: [_green, Color(0xFF2D8A60)]),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              'TODAY’S SALES',
              style: TextStyle(color: Colors.white70, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _peso(amount),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Total value of sales recorded today',
          style: TextStyle(color: Colors.white70),
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
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: tint,
              child: Icon(icon, color: _green),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: _green,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: FilledButton.styleFrom(backgroundColor: _green),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _lightGreen,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: _green,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_peso(product.price)}  •  ${product.stock} in stock',
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
                        isThreeLine: false,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.product == null ? 'Add product' : 'Edit product'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    required this.onSave,
    super.key,
  });

  final List<StoreProduct> products;
  final void Function(List<SaleLine>, bool, String?) onSave;

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _quantities = <String, int>{};
  final _customerController = TextEditingController();
  bool _isPaid = true;

  @override
  void dispose() {
    _customerController.dispose();
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
                      TextField(
                        controller: _customerController,
                        decoration: const InputDecoration(
                          labelText: 'Customer name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
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
                          backgroundColor: _green,
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
            const CircleAvatar(
              backgroundColor: _lightGreen,
              child: Icon(Icons.shopping_basket_outlined, color: _green),
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

class UtangLedgerScreen extends StatelessWidget {
  const UtangLedgerScreen({
    required this.customers,
    required this.onPayment,
    super.key,
  });

  final List<StoreCustomer> customers;
  final void Function(StoreCustomer, double) onPayment;

  @override
  Widget build(BuildContext context) {
    final total = customers.fold<double>(
      0,
      (sum, customer) => sum + customer.balance,
    );
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
                '${customers.where((customer) => customer.balance > 0).length} customers with a balance',
              ),
            ],
          ),
        ),
        Expanded(
          child: customers.isEmpty
              ? const Center(child: Text('No customer balances yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: customers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
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
                        subtitle: const Text('Outstanding balance'),
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
                              onPayment: onPayment,
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
  final void Function(StoreCustomer, double) onPayment;

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
                            '${date.day}/${date.month}/${date.year} · '
                            '${date.hour.toString().padLeft(2, '0')}:'
                            '${date.minute.toString().padLeft(2, '0')}',
                          ),
                          trailing: Text(
                            '${entry.isPayment ? '−' : '+'}${_peso(entry.amount)}',
                            style: TextStyle(
                              color: entry.isPayment ? _green : const Color(0xFFB94A32),
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
              backgroundColor: _green,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _recordPayment(BuildContext context) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record payment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount received',
            prefixText: '₱ ',
            helperText: 'Balance: ${_peso(customer.balance)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value == null || value <= 0 || value > customer.balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Enter an amount up to ${_peso(customer.balance)}.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Save payment'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null) onPayment(customer, amount);
  }
}

class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({required this.sales, super.key});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    final today = sales
        .where((sale) => _sameDay(sale.date, DateTime.now()))
        .toList();
    final total = today.fold<double>(0, (sum, sale) => sum + sale.total);
    final paid = today
        .where((sale) => sale.isPaid)
        .fold<double>(0, (sum, sale) => sum + sale.total);
    final credit = total - paid;
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
                tint: _lightGreen,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.menu_book_outlined,
                label: 'Utang sales',
                value: _peso(credit),
                tint: const Color(0xFFFFF3DF),
                onTap: () {},
              ),
            ),
          ],
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
