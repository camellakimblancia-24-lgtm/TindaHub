import 'package:flutter/material.dart';
import 'main.dart'; // Imports StoreProduct, StoreCustomer, SaleRecord

class StoreProvider extends ChangeNotifier {
  final List<StoreProduct> _products = [];
  final List<StoreCustomer> _customers = [];
  final List<SaleRecord> _sales = [];

  List<StoreProduct> get products => _products;
  List<StoreCustomer> get customers => _customers;
  List<SaleRecord> get sales => _sales;

  void saveProduct(StoreProduct product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
    notifyListeners(); // Updates all listening screens
  }

  void saveSale(SaleRecord sale) {
    _sales.add(sale);
    // Deduct stock and update utang balances...
    notifyListeners();
  }
}