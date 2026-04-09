import 'dart:convert';
import 'package:http/http.dart' as http;

/// Parsed barcode data — could come from QR code content or external API lookup.
class BarcodeProductInfo {
  final String? name;
  final String? brand;
  final String? description;
  final String? category;
  final double? price;
  final String? supplier;
  final String? imageUrl;
  final String barcode;

  BarcodeProductInfo({
    this.name,
    this.brand,
    this.description,
    this.category,
    this.price,
    this.supplier,
    this.imageUrl,
    required this.barcode,
  });

  bool get hasData =>
      name != null || brand != null || category != null || price != null;
}

class BarcodeLookupService {
  /// Parse product info from the raw scanned barcode value.
  /// Handles:
  ///   1. QR codes containing JSON data with product info
  ///   2. QR codes containing delimited data (e.g. "name|category|price")
  ///   3. Standard numeric barcodes — tries Open Food Facts then UPC Items DB
  static Future<BarcodeProductInfo> lookup(String rawValue) async {
    // 1. Try JSON parse (QR codes with structured data)
    final jsonResult = _tryJsonParse(rawValue);
    if (jsonResult != null && jsonResult.hasData) return jsonResult;

    // 2. Try delimited parse (pipe, semicolon, or comma-separated)
    final delimResult = _tryDelimitedParse(rawValue);
    if (delimResult != null && delimResult.hasData) return delimResult;

    // 3. If it's a numeric barcode (UPC/EAN), try external APIs
    final cleanBarcode = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanBarcode.length >= 8 && cleanBarcode.length <= 14) {
      // Try Open Food Facts first
      final offResult = await _tryOpenFoodFactsLookup(cleanBarcode);
      if (offResult != null && offResult.hasData) return offResult;

      // Fallback: try UPC Items DB
      final upcResult = await _tryUpcItemsDbLookup(cleanBarcode);
      if (upcResult != null && upcResult.hasData) return upcResult;
    }

    // 4. No data found — just return the barcode
    return BarcodeProductInfo(barcode: rawValue);
  }

  /// Try to parse JSON from the barcode value.
  static BarcodeProductInfo? _tryJsonParse(String rawValue) {
    try {
      final data = json.decode(rawValue);
      if (data is Map<String, dynamic>) {
        return BarcodeProductInfo(
          barcode: data['barcode']?.toString() ??
              data['code']?.toString() ??
              rawValue,
          name: data['name']?.toString() ??
              data['product_name']?.toString() ??
              data['product']?.toString(),
          brand: data['brand']?.toString() ??
              data['manufacturer']?.toString(),
          description: data['description']?.toString(),
          category: data['category']?.toString() ??
              data['type']?.toString(),
          price: _parseDouble(data['price']?.toString() ??
              data['selling_price']?.toString()),
          supplier: data['supplier']?.toString(),
          imageUrl: data['image']?.toString() ??
              data['image_url']?.toString(),
        );
      }
    } catch (_) {
      // Not JSON
    }
    return null;
  }

  /// Try to parse pipe/semicolon/comma delimited data.
  /// Expected format: "barcode|name|category|price|supplier"
  static BarcodeProductInfo? _tryDelimitedParse(String rawValue) {
    String? delimiter;
    if (rawValue.contains('|')) {
      delimiter = '|';
    } else if (rawValue.contains(';') && !rawValue.startsWith('http')) {
      delimiter = ';';
    }

    if (delimiter != null) {
      final parts = rawValue.split(delimiter).map((s) => s.trim()).toList();
      if (parts.length >= 2) {
        return BarcodeProductInfo(
          barcode: parts[0].isNotEmpty ? parts[0] : rawValue,
          name: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
          category: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
          price: parts.length > 3 ? _parseDouble(parts[3]) : null,
          supplier: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
        );
      }
    }
    return null;
  }

  /// Try Open Food Facts API for standard product barcodes.
  static Future<BarcodeProductInfo?> _tryOpenFoodFactsLookup(
      String barcode) async {
    try {
      final url = Uri.parse(
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          return BarcodeProductInfo(
            barcode: barcode,
            name: product['product_name']?.toString(),
            brand: product['brands']?.toString(),
            description: product['generic_name']?.toString() ??
                product['ingredients_text']?.toString(),
            category: _mapOpenFoodFactsCategory(
                product['categories']?.toString()),
            supplier: product['brands']?.toString(),
            imageUrl: product['image_front_small_url']?.toString() ??
                product['image_url']?.toString(),
          );
        }
      }
    } catch (_) {
      // API lookup failed
    }
    return null;
  }

  /// Try UPC Items DB as a fallback API.
  static Future<BarcodeProductInfo?> _tryUpcItemsDbLookup(
      String barcode) async {
    try {
      final url =
          Uri.parse('https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && (data['items'] as List).isNotEmpty) {
          final item = data['items'][0];
          final images = item['images'] as List?;
          return BarcodeProductInfo(
            barcode: barcode,
            name: item['title']?.toString(),
            brand: item['brand']?.toString(),
            description: item['description']?.toString(),
            category: item['category']?.toString(),
            supplier: item['brand']?.toString(),
            imageUrl: images != null && images.isNotEmpty
                ? images.first.toString()
                : null,
          );
        }
      }
    } catch (_) {
      // Fallback API failed
    }
    return null;
  }

  /// Map Open Food Facts categories to our local categories.
  static String? _mapOpenFoodFactsCategory(String? categories) {
    if (categories == null || categories.isEmpty) return null;

    final lower = categories.toLowerCase();
    if (lower.contains('beverage') || lower.contains('drink')) {
      return 'Beverages';
    }
    if (lower.contains('dairy') ||
        lower.contains('milk') ||
        lower.contains('cheese')) {
      return 'Dairy';
    }
    if (lower.contains('snack') ||
        lower.contains('chip') ||
        lower.contains('biscuit')) {
      return 'Snacks';
    }
    if (lower.contains('personal') ||
        lower.contains('hygiene') ||
        lower.contains('soap')) {
      return 'Personal Care';
    }
    if (lower.contains('household') || lower.contains('cleaning')) {
      return 'Household';
    }
    if (lower.contains('electronic')) {
      return 'Electronics';
    }
    if (lower.contains('clothing') || lower.contains('apparel')) {
      return 'Clothing';
    }
    if (lower.contains('stationery') || lower.contains('office')) {
      return 'Stationery';
    }
    if (lower.contains('food') || lower.contains('grocery')) {
      return 'Groceries';
    }
    return 'Groceries';
  }

  static double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }
}
