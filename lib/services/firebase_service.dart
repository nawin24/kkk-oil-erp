import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  static const String apiKey = 'AIzaSyC6674SxdJIGOlmyIdZZK0PTS3VK55Srks';
  static const String projectId = 'kkk-oil-erp';
  static const String authDomain = 'kkk-oil-erp.firebaseapp.com';
  static const String storageBucket = 'kkk-oil-erp.firebasestorage.app';
  static const String messagingSenderId = '959332742121';
  static const String appId = '1:959332742121:web:87fe3420e13815b28b1178';

  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  static bool get isConfigured => apiKey.isNotEmpty && projectId.isNotEmpty;

  /// Fetches all documents from a Firestore collection
  static Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    if (!isConfigured) return [];
    final url = Uri.parse('$_baseUrl/$collection?key=$apiKey&pageSize=300');

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final docs = data['documents'] as List<dynamic>?;
        if (docs == null) return [];

        final result = <Map<String, dynamic>>[];
        for (final doc in docs) {
          final fields = doc['fields'] as Map<String, dynamic>?;
          if (fields != null) {
            final parsed = decodeFirestoreFields(fields);
            // Ensure ID is present
            if (!parsed.containsKey('id')) {
              final name = doc['name'] as String? ?? '';
              parsed['id'] = name.split('/').last;
            }
            result.add(parsed);
          }
        }
        return result;
      } else {
        if (kDebugMode && res.statusCode != 403 && res.statusCode != 401 && res.statusCode != 404) {
          print('Firestore fetch $collection error: ${res.statusCode} ${res.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        final err = e.toString();
        if (!err.contains('Failed to fetch') && !err.contains('XMLHttpRequest error')) {
          print('Firestore fetch $collection exception: $e');
        }
      }
      return [];
    }
  }

  /// Upserts a document to a Firestore collection
  static Future<bool> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    if (!isConfigured) return false;
    final url = Uri.parse('$_baseUrl/$collection/$docId?key=$apiKey');

    try {
      final body = jsonEncode({
        'fields': encodeFirestoreFields(data),
      });

      final res = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 403 || res.statusCode == 401) {
        return false;
      }
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        final err = e.toString();
        if (!err.contains('Failed to fetch') && !err.contains('XMLHttpRequest error')) {
          print('Firestore write $collection/$docId exception: $e');
        }
      }
      return false;
    }
  }

  /// Deletes a document from a Firestore collection
  static Future<bool> deleteDocument(String collection, String docId) async {
    if (!isConfigured) return false;
    final url = Uri.parse('$_baseUrl/$collection/$docId?key=$apiKey');

    try {
      final res = await http.delete(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 403 || res.statusCode == 401) {
        return false;
      }
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        final err = e.toString();
        if (!err.contains('Failed to fetch') && !err.contains('XMLHttpRequest error')) {
          print('Firestore delete $collection/$docId exception: $e');
        }
      }
      return false;
    }
  }

  /// Decodes Firestore REST fields map to standard Dart map
  static Map<String, dynamic> decodeFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((k, v) {
      result[k] = _decodeValue(v);
    });
    return result;
  }

  static dynamic _decodeValue(dynamic fv) {
    if (fv is! Map) return fv;
    if (fv.containsKey('stringValue')) return fv['stringValue'];
    if (fv.containsKey('integerValue')) {
      final s = fv['integerValue'];
      return int.tryParse(s.toString()) ?? 0;
    }
    if (fv.containsKey('doubleValue')) {
      final d = fv['doubleValue'];
      return (d is num) ? d.toDouble() : double.tryParse(d.toString()) ?? 0.0;
    }
    if (fv.containsKey('booleanValue')) return fv['booleanValue'] == true;
    if (fv.containsKey('timestampValue')) return fv['timestampValue'];
    if (fv.containsKey('nullValue')) return null;
    if (fv.containsKey('mapValue')) {
      final m = fv['mapValue']['fields'] as Map<String, dynamic>? ?? {};
      return decodeFirestoreFields(m);
    }
    if (fv.containsKey('arrayValue')) {
      final arr = fv['arrayValue']['values'] as List<dynamic>? ?? [];
      return arr.map(_decodeValue).toList();
    }
    return null;
  }

  /// Encodes standard Dart map to Firestore REST fields map
  static Map<String, dynamic> encodeFirestoreFields(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((k, v) {
      if (v != null) {
        result[k] = _encodeValue(v);
      }
    });
    return result;
  }

  static Map<String, dynamic> _encodeValue(dynamic v) {
    if (v is String) return {'stringValue': v};
    if (v is int) return {'integerValue': v.toString()};
    if (v is double) return {'doubleValue': v};
    if (v is bool) return {'booleanValue': v};
    if (v is Map) {
      return {
        'mapValue': {
          'fields': encodeFirestoreFields(v.cast<String, dynamic>()),
        },
      };
    }
    if (v is List) {
      return {
        'arrayValue': {
          'values': v.map(_encodeValue).toList(),
        },
      };
    }
    return {'stringValue': v.toString()};
  }
}
