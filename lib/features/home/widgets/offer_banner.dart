import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/storage_helper.dart';
import '../../courses/models/course_model.dart';
import '../../courses/screens/course_detail_screen.dart';

class OfferBanner extends StatefulWidget {
  const OfferBanner({super.key});

  @override
  State<OfferBanner> createState() => _OfferBannerState();
}

class _OfferBannerState extends State<OfferBanner> {
  Course? _featuredCourse;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeatured();
  }

  Future<void> _fetchFeatured() async {
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse(
            "https://api.aktuhub.in/api/courses?action=featured"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data =
        body is Map && body['data'] is List
            ? body['data']
            : body is List
            ? body
            : [];

        if (data.isNotEmpty && mounted) {
          setState(() {
            _featuredCourse = Course.fromJson(
                data.first as Map<String, dynamic>);
            _loading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("OFFER BANNER ERROR: $e");
    }

    // Fallback: fetch first course from all courses
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse("https://api.aktuhub.in/api/courses"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data =
        body is Map && body['data'] is List ? body['data'] : [];
        if (data.isNotEmpty && mounted) {
          setState(() {
            _featuredCourse =
                Course.fromJson(data.first as Map<String, dynamic>);
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    final course = _featuredCourse;

    // If no course found — show static promotional banner
    if (course == null) {
      return _staticBanner(context);
    }

    final hasOld = course.oldPrice.isNotEmpty && course.oldPrice != "0";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(course: course),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background thumbnail
              if (course.thumbnail.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    "https://api.aktuhub.in/api/uploads/courses/${course.thumbnail}",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.black87),
                  ),
                ),

              // Dark overlay
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.transparent,
                        Color(0xDD000000),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "FEATURED COURSE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Instructor
                    if (course.instructor.isNotEmpty)
                      Text(
                        "by ${course.instructor}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Price + CTA row
                    Row(
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasOld)
                              Text(
                                "₹${course.oldPrice}",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            Text(
                              "₹${course.price}",
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // Enroll button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Enroll Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),

                        if (hasOld) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${(((double.tryParse(course.oldPrice) ?? 0) - (double.tryParse(course.price) ?? 0)) / (double.tryParse(course.oldPrice) ?? 1) * 100).toStringAsFixed(0)}% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staticBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "SPECIAL OFFER",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Inter'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Bridal Mehndi Masterclass",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Learn advanced techniques with Arun",
            style:
            TextStyle(color: Colors.white70, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Enroll Now - 30% Off",
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}