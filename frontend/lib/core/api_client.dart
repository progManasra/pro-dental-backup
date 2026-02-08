import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'storage.dart';

class ApiClient {
  final Storage storage;
  ApiClient(this.storage);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final uri = Uri.parse("${AppConstants.apiBaseUrl}$path");
    final headers = <String, String>{
      "Content-Type": "application/json",
    };

    if (auth) {
      final t = await storage.token();
      if (t != null) headers["Authorization"] = "Bearer $t";
    }

    final res = await http.post(uri, headers: headers, body: jsonEncode(body));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "API Error");
    }
    return data;
  }
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body, {bool auth = false}) async {
  final uri = Uri.parse("${AppConstants.apiBaseUrl}$path");
  final headers = <String, String>{
    "Content-Type": "application/json",
  };

  if (auth) {
    final t = await storage.token();
    if (t != null) headers["Authorization"] = "Bearer $t";
  }

  final res = await http.put(uri, headers: headers, body: jsonEncode(body));
  final data = jsonDecode(res.body) as Map<String, dynamic>;

  if (res.statusCode >= 400) {
    throw Exception(data["error"] ?? "API Error");
  }

  return data;
}


  Future<Map<String, dynamic>> get(String path, {bool auth = false}) async {
    final uri = Uri.parse("${AppConstants.apiBaseUrl}$path");
    final headers = <String, String>{};

    if (auth) {
      final t = await storage.token();
      if (t != null) headers["Authorization"] = "Bearer $t";
    }

    final res = await http.get(uri, headers: headers);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "API Error");
    }
    return data;
  }
  Future<void> delete(String path, {bool auth = false}) async {
    final uri = Uri.parse("${AppConstants.apiBaseUrl}$path");
    final headers = <String, String>{};

    if (auth) {
      final t = await storage.token();
      if (t != null) headers["Authorization"] = "Bearer $t";
    }

    final res = await http.delete(uri, headers: headers);
    if (res.statusCode >= 400) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(data["error"] ?? "API Error");
    }
  }
}
