import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/course_model.dart';

class CourseService {
  static const String baseUrl = "https://api.aktuhub.in/api";

  static Future<List<Course>> getCourses({
    required String token,
    String? category,
    String? level,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      "page": page.toString(),
    };

    if (category != null && category.isNotEmpty) {
      queryParams["category"] = category;
    }

    if (level != null && level.isNotEmpty) {
      queryParams["level"] = _mapLevel(level);
    }

    if (search != null && search.isNotEmpty) {
      queryParams["search"] = search;
    }

    final uri =
    Uri.parse("$baseUrl/courses").replace(queryParameters: queryParams);

    debugPrint("🌐 API CALL: $uri");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    debugPrint("📡 STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = decoded['data'] as List? ?? [];
      return list.map((e) => Course.fromJson(e)).toList();
    } else {
      throw Exception("API ERROR: ${response.statusCode}");
    }
  }

  // ✅ API mein level values: "Advanced", "Medium", "Basic" (capital)
  static String _mapLevel(String level) {
    switch (level) {
      case "Beginner":
        return "Basic";
      case "Intermediate":
        return "Medium";
      case "Pro":
        return "Advanced";
      default:
      // Agar already "Basic/Medium/Advanced" aaye toh direct pass karo
        return level;
    }
  }
}