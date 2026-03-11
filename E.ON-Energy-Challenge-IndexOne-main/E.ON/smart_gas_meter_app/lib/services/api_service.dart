import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_gas_meter_app/models/reading.dart';

class ApiService {
  final String baseUrl = "http://192.168.61.24:8000";

  Future<List<Reading>> fetchReadings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/readings'));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data.map((item) => Reading.fromJson(item)).toList();
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch readings: $e");
    }
  }

  Future<int> fetchRequestInterval() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/request-interval'));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['request_interval_seconds'] ?? 120;
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch request interval: $e");
    }
  }

  Future<void> updateRequestInterval(int seconds) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/request-interval?seconds=$seconds'),
    );

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    throw Exception("Failed to update request interval: $e");
  }
}

Future<Map<String, dynamic>> fetchAnalytics() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/analytics'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'] ?? {};
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Failed to fetch analytics: $e");
  }
}

Future<Map<String, dynamic>> fetchPrediction() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/prediction'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'] ?? {};
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch prediction: $e');
  }
}
}