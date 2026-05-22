import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/helpers/storage_helper.dart';
import '../courses/screens/course_detail_screen.dart';
import '../courses/models/course_model.dart';

// ─── MODEL ───────────────────────────────────────────────
class EnrolledCourse {
  final int id;
  final String title;
  final String thumbnail;
  final String level;
  final String duration;
  final double progress;
  final String enrolledAt;

  EnrolledCourse({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.level,
    required this.duration,
    required this.progress,
    required this.enrolledAt,
  });

  factory EnrolledCourse.fromJson(Map<String, dynamic> json) {
    return EnrolledCourse(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      progress: double.tryParse(json['progress']?.toString() ?? '0') ?? 0.0,
      enrolledAt: json['enrolled_at']?.toString() ?? '',
    );
  }
}

// ─── SCREEN ───────────────────────────────────────────────
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with SingleTickerProviderStateMixin {
  List<EnrolledCourse> _courses = [];
  bool _loading = true;
  bool _hasError = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMyCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyCourses() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse(
            "https://api.aktuhub.in/api/enroll?action=my-courses"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data =
        body is Map && body['data'] is List ? body['data'] : [];
        if (mounted) {
          setState(() {
            _courses =
                data.map((e) => EnrolledCourse.fromJson(e)).toList();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint("MY COURSES ERROR: $e");
      if (mounted) setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  List<EnrolledCourse> get _inProgress =>
      _courses.where((c) => c.progress > 0 && c.progress < 100).toList();
  List<EnrolledCourse> get _notStarted =>
      _courses.where((c) => c.progress == 0).toList();
  List<EnrolledCourse> get _completed =>
      _courses.where((c) => c.progress >= 100).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "My Learning",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Inter'),
          tabs: [
            Tab(text: "All (${_courses.length})"),
            Tab(text: "In Progress (${_inProgress.length})"),
            Tab(text: "Done (${_completed.length})"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildError()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(_courses),
          _buildList(_inProgress),
          _buildList(_completed),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("Failed to load courses",
              style: TextStyle(
                  color: Colors.grey, fontSize: 16, fontFamily: 'Inter')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchMyCourses,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text("Retry",
                style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<EnrolledCourse> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "No courses here yet",
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyCourses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _EnrolledCourseCard(course: list[i]),
      ),
    );
  }
}

// ─── ENROLLED COURSE CARD ────────────────────────────────
class _EnrolledCourseCard extends StatelessWidget {
  final EnrolledCourse course;
  const _EnrolledCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final progress = (course.progress / 100).clamp(0.0, 1.0);
    final progressPct = course.progress.toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  "https://api.aktuhub.in/api/uploads/courses/${course.thumbnail}",
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: Colors.grey.shade100,
                    child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.black26)),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x88000000)],
                      ),
                    ),
                  ),
                ),
                if (course.level.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _levelColor(course.level),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.level,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                // Progress badge
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$progressPct% done",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      course.progress >= 100
                          ? Colors.green
                          : AppColors.primary,
                    ),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    if (course.duration.isNotEmpty) ...[
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        course.duration,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontFamily: 'Inter'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // Navigate to course — build a minimal Course object
                        final c = Course(
                          id: course.id,
                          title: course.title,
                          thumbnail: course.thumbnail,
                          price: "0",
                          level: course.level,
                          category: "",
                          description: "",
                          duration: course.duration,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailScreen(course: c),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: course.progress >= 100
                              ? Colors.green
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          course.progress >= 100
                              ? "Review"
                              : course.progress > 0
                              ? "Continue"
                              : "Start",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case "basic":
      case "beginner":
        return Colors.green;
      case "medium":
      case "intermediate":
        return Colors.orange;
      case "advanced":
      case "pro":
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}