import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenFoodFactsProduct {
  const OpenFoodFactsProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.size,
    this.imageUrl,
  });

  final String barcode;
  final String name;
  final String? brand;
  final String? size;
  final String? imageUrl;

  factory OpenFoodFactsProduct.fromJson(
    Map<String, dynamic> json, {
    required String barcode,
  }) {
    final product = json['product'];
    final status = json['status'];
    if ((status != 1 && status != 'success') ||
        product is! Map<String, dynamic>) {
      throw const FormatException(
        'The API response does not contain a product.',
      );
    }

    String? readString(String key) {
      final value = product[key];
      if (value is! String || value.trim().isEmpty) return null;
      return value.trim();
    }

    final name = readString('product_name');
    if (name == null) {
      throw const FormatException(
        'The product has no name in the API response.',
      );
    }

    return OpenFoodFactsProduct(
      barcode:
          json['code'] is String && (json['code'] as String).trim().isNotEmpty
          ? (json['code'] as String).trim()
          : barcode,
      name: name,
      brand: readString('brands'),
      size: readString('quantity'),
      imageUrl: readString('image_front_small_url'),
    );
  }
}

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<OpenFoodFactsProduct?> lookupByBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      throw ArgumentError.value(barcode, 'barcode', 'Barcode cannot be empty.');
    }
    if (!RegExp(r'^\d+$').hasMatch(normalizedBarcode)) {
      throw ArgumentError.value(
        barcode,
        'barcode',
        'Barcode must contain digits only.',
      );
    }

    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v3/product/$normalizedBarcode.json',
    );
    final response = await _client.get(
      uri,
      headers: const {'User-Agent': 'TindaHub/1.0'},
    );

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Open Food Facts returned HTTP ${response.statusCode}.',
        uri,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid response.');
    }
    if (decoded['status'] == 0 || decoded['status'] == 'failure') {
      return null;
    }

    return OpenFoodFactsProduct.fromJson(decoded, barcode: normalizedBarcode);
  }

  void close() => _client.close();
}
