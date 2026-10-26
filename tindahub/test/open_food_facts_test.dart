import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tindahub/open_food_facts.dart';

void main() {
  group('OpenFoodFactsService', () {
    test('maps a barcode response to the product model', () async {
      late Uri requestedUri;
      late Map<String, String> requestHeaders;
      final service = OpenFoodFactsService(
        client: MockClient((request) async {
          requestedUri = request.url;
          requestHeaders = request.headers;
          return http.Response(
            jsonEncode({
              'code': '3274080005003',
              'status': 1,
              'product': {
                'product_name': 'Bottled water',
                'brands': 'Cristaline',
                'quantity': '1500 ml',
                'image_front_small_url': 'https://example.org/water.jpg',
              },
            }),
            200,
          );
        }),
      );

      final product = await service.lookupByBarcode('3274080005003');

      expect(requestedUri.path, '/api/v3/product/3274080005003.json');
      expect(requestHeaders['User-Agent'], 'TindaHub/1.0');
      expect(product?.barcode, '3274080005003');
      expect(product?.name, 'Bottled water');
      expect(product?.brand, 'Cristaline');
      expect(product?.size, '1500 ml');
      expect(product?.imageUrl, 'https://example.org/water.jpg');
      service.close();
    });

    test('returns null when the barcode is not found', () async {
      final service = OpenFoodFactsService(
        client: MockClient(
          (request) async =>
              http.Response(jsonEncode({'status': 0, 'product': {}}), 200),
        ),
      );

      expect(await service.lookupByBarcode('123456'), isNull);
      service.close();
    });

    test('accepts the sample success status string', () async {
      final service = OpenFoodFactsService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': '3274080005003',
              'status': 'success',
              'product': {'product_name': 'Bottled water'},
            }),
            200,
          ),
        ),
      );

      expect(
        (await service.lookupByBarcode('3274080005003'))?.name,
        'Bottled water',
      );
      service.close();
    });

    test('rejects a non-digit barcode', () async {
      final service = OpenFoodFactsService(
        client: MockClient((request) async => http.Response('', 200)),
      );

      expect(
        () => service.lookupByBarcode('not-a-barcode'),
        throwsArgumentError,
      );
      service.close();
    });
  });
}
