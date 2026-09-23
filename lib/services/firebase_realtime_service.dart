import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseRealtimeService {
  final String databaseUrl = "https://piggy-trunk-default-rtdb.firebaseio.com";

  Future<List<Map<String, dynamic>>> fetchInvestments(String authToken) async {
    final url = Uri.parse("$databaseUrl/investments.json?auth=$authToken");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded == null) return [];

      final Map<String, dynamic> rawTree = Map<String, dynamic>.from(decoded);
      return rawTree.entries.map((entry) {
        final record = Map<String, dynamic>.from(entry.value as Map);
        record['id'] = entry.key;
        return record;
      }).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchInventory(String authToken) async {
    final url = Uri.parse("$databaseUrl/inventory_products.json?auth=$authToken");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded == null) return [];

      final Map<String, dynamic> rawTree = Map<String, dynamic>.from(decoded);
      return rawTree.entries.map((entry) {
        final product = Map<String, dynamic>.from(entry.value as Map);
        product['product_id'] = entry.key;
        return product;
      }).toList();
    }
    return [];
  }
}
