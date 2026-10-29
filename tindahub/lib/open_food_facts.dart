import 'dart:async';
import 'dart:convert';
 
import 'package:http/http.dart' as http;
 
/// The barcode typed by the owner is empty or not digits-only.
class InvalidBarcodeException implements Exception {
  const InvalidBarcodeException(this.message);
 
  final String message;
 
  @override
  String toString() => message;
}
 
/// No internet, DNS failure, or the request timed out.
class LookupOfflineException implements Exception {
  const LookupOfflineException();
 
  @override
  String toString() => 'No internet connection.';
}
 
/// Open Food Facts answered with an unexpected HTTP status.
class LookupServerException implements Exception {
  const LookupServerException(this.statusCode);
 
  final int statusCode;
 
  @override
  String toString() => 'Open Food Facts returned HTTP $statusCode.';
}
 
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
 
  /// Returns the product, or null if Open Food Facts does not know the barcode.
  ///
  /// Throws [InvalidBarcodeException], [LookupOfflineException],
  /// [LookupServerException], or [FormatException] (invalid response).
  Future<OpenFoodFactsProduct?> lookupByBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      throw const InvalidBarcodeException('Enter a barcode to look up.');
    }
    if (!RegExp(r'^\d+$').hasMatch(normalizedBarcode)) {
      throw const InvalidBarcodeException(
        'A barcode can only contain digits.',
      );
    }
 
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v3/product/$normalizedBarcode.json',
    );
 
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'User-Agent': 'TindaHub/1.0'})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const LookupOfflineException();
    } on http.ClientException {
      // The http package wraps socket/DNS failures in ClientException.
      throw const LookupOfflineException();
    }
 
    // v3 answers 404 for an unknown barcode.
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw LookupServerException(response.statusCode);
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
 

