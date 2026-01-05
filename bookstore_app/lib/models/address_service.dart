import 'dart:convert';
import 'dart:io';

import 'address.dart';

class AddressService {
  AddressService({required this.baseUrl});

  final String baseUrl;

  Future<List<Address>> fetchAddresses(int userId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/addresses/$userId');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed.');
      }

      if (body.isEmpty) return [];
      final data = jsonDecode(body) as List<dynamic>;
      return data
          .map((item) => Address.fromJson(item as Map<String, dynamic>))
          .where((address) => address.id > 0)
          .toList();
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<Address> createAddress({
    required int userId,
    required String fullName,
    required String phoneNumber,
    required String addressLine,
    String? addressLineNew,
    required bool isDefault,
  }) async {
    final data = await _post('/api/addresses', {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'addressLineNew': addressLineNew,
      'isDefault': isDefault,
    });
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<void> setDefaultAddress({
    required int userId,
    required int addressId,
  }) async {
    await _patch('/api/addresses/$addressId/default', {
      'userId': userId,
    });
  }

  Future<Address> updateAddress({
    required int addressId,
    required int userId,
    required String fullName,
    required String phoneNumber,
    required String addressLine,
    String? addressLineNew,
    required bool isDefault,
  }) async {
    final data = await _patch('/api/addresses/$addressId', {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'addressLineNew': addressLineNew,
      'isDefault': isDefault,
    });
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteAddress({
    required int addressId,
    required int userId,
  }) async {
    await _delete('/api/addresses/$addressId', {
      'userId': userId,
    });
  }

  Future<dynamic> _post(String path, Map<String, dynamic> payload) async {
    return _sendJson('POST', path, payload);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> payload) async {
    return _sendJson('PATCH', path, payload);
  }

  Future<void> _delete(String path, Map<String, dynamic> payload) async {
    await _sendJson('DELETE', path, payload);
  }

  Future<dynamic> _sendJson(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed.');
      }
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }
}
