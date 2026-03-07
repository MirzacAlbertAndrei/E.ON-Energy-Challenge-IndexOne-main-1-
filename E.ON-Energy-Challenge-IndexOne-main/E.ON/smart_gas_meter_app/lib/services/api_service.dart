import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/reading.dart';

class ApiService {

  static Future<List<Reading>> getReadings() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/readings"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List list = data['data'];

      return list.map((e) => Reading.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load readings");
    }
  }

  static Future<void> setInterval(int seconds) async {
    await http.post(
      Uri.parse("${ApiConfig.baseUrl}/request-interval?seconds=$seconds"),
    );
  }
}