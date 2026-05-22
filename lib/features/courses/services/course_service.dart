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

    // Backend CourseController checks $_GET['category'] as category name string
    if (category != null && category.trim().isNotEmpty) {
      queryParams["category"] = category.trim();
    }

    // Backend searchCourses uses level as-is — API stores Basic/Medium/Advanced
    if (level != null && level.trim().isNotEmpty) {
      queryParams["level"] = _mapLevel(level.trim());
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams["search"] = search.trim();
    }

    final uri =
    Uri.parse("$baseUrl/courses").replace(queryParameters: queryParams);

    debugPrint("🌐 CourseService GET: $uri");

    try {
      final response = await http
          .get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      )
          .timeout(const Duration(seconds: 20));

      debugPrint("📡 STATUS: ${response.statusCode}");
      debugPrint("📦 BODY: ${response.body.substring(0, response.body.length.clamp(0, 300))}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // API wraps in { success, data: [...] }
        final List<dynamic> list;
        if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'] as List;
        } else if (decoded is List) {
          list = decoded;
        } else {
          debugPrint("❌ Unexpected API shape: ${decoded.runtimeType}");
          return [];
        }

        final courses = list
            .map((e) {
          try {
            return Course.fromJson(e as Map<String, dynamic>);
          } catch (err) {
            debugPrint("⚠️ Course.fromJson error: $err — item: $e");
            return null;
          }
        })
            .whereType<Course>()
            .toList();

        debugPrint("✅ Parsed ${courses.length} courses");
        return courses;
      } else {
        debugPrint("❌ API ERROR: ${response.statusCode} — ${response.body}");
        throw Exception("API ERROR: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ CourseService exception: $e");
      rethrow;
    }
  }

  /// Maps UI filter labels → API level values stored in DB (Basic/Medium/Advanced)
  static String _mapLevel(String level) {
    switch (level.toLowerCase()) {
      case "beginner":
      case "basic":
        return "Basic";
      case "intermediate":
      case "medium":
        return "Medium";
      case "pro":
      case "advanced":
        return "Advanced";
      default:
      // Return as-is if already correct casing
        return level;
    }
  }
}