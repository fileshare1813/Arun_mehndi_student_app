import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'course_preview_screen.dart';
import '../../courses/models/course_model.dart';
import 'package:mehndi_student_app/features/instructor/screens/instructor_profile_screen.dart';
import 'package:mehndi_student_app/features/courses/widgets/course_reviews_tab.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/storage_helper.dart';
import '../../../core/api/api_endpoints.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() =>
      _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWishlisted = false;
  int _selectedTab = 1;

  bool _enrolling = false;
  bool _isEnrolled = false;

  List<Map<String, dynamic>> _modules = [];
  bool _loadingModules = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _checkEnrollment();
    _fetchCourseStructure();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkEnrollment() async {
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse(
            "${ApiEndpoints.baseUrl}/enroll?action=check-access&course_id=${widget.course.id}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (mounted) {
          setState(() => _isEnrolled = data['has_access'] == true);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCourseStructure() async {
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse(
            "${ApiEndpoints.courseDetail}?id=${widget.course.id}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        final List<dynamic> rawModules = data['modules'] ?? [];
        if (mounted) {
          setState(() {
            _modules = rawModules.map((m) {
              return {
                "title": m['title']?.toString() ?? '',
                "expanded": false,
                "items": (m['lessons'] as List? ?? []).map((l) {
                  return {
                    "title": l['title']?.toString() ?? '',
                    "duration": l['duration']?.toString() ?? '',
                    "free": (l['is_preview'] == 1 ||
                        l['is_preview'] == true),
                  };
                }).toList(),
              };
            }).toList();
            _loadingModules = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingModules = false);
      }
    } catch (e) {
      debugPrint("COURSE STRUCTURE ERROR: $e");
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  Future<void> _enroll() async {
    if (_isEnrolled) return;
    setState(() => _enrolling = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/enroll?action=enroll"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"course_id": widget.course.id}),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (mounted) {
        if (body['success'] == true ||
            (body['message']
                ?.toString()
                .toLowerCase()
                .contains('success') ??
                false)) {
          setState(() => _isEnrolled = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Enrolled successfully! Start learning."),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
            Text(body['message'] ?? "Enrollment failed"),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Server error. Please try again."),
            backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _enrolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final hasOldPrice =
        course.oldPrice.isNotEmpty && course.oldPrice != "0";

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _buildVideoHeader(course)),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _badge("Best Seller", AppColors.gold,
                              const Color(0xFFFFF8E1)),
                          const SizedBox(width: 8),
                          if (course.level.isNotEmpty)
                            _badge(
                              _capitalize(course.level),
                              Colors.black87,
                              Colors.grey.shade100,
                            ),
                          if (_isEnrolled) ...[
                            const SizedBox(width: 8),
                            _badge("Enrolled", Colors.green,
                                Colors.green.shade50),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(course.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                            height: 1.3,
                            fontFamily: 'PlayfairDisplay',
                          )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.gold, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            course.rating > 0
                                ? course.rating.toStringAsFixed(1)
                                : "4.8",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1C1C1E)),
                          ),
                          Text(
                            " (${course.totalReviews > 0 ? course.totalReviews : "1.2k"})",
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.people_outline,
                              size: 16,
                              color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            "${course.totalStudents > 0 ? course.totalStudents : "5.4k"} Enrolled",
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${course.price}",
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontFamily: 'PlayfairDisplay',
                              )),
                          if (hasOldPrice) ...[
                            const SizedBox(width: 10),
                            Text("₹${course.oldPrice}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                  decoration:
                                  TextDecoration.lineThrough,
                                )),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: Text("50% OFF",
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 2,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Inter'),
                    tabs: const [
                      Tab(text: "About"),
                      Tab(text: "Syllabus"),
                      Tab(text: "Reviews"),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _selectedTab == 0
                      ? _buildAboutTab(course)
                      : _selectedTab == 1
                      ? _buildSyllabusTab()
                      : CourseReviewsTab(
                      courseId: course.id),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildEnrollBar(course, hasOldPrice),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoHeader(Course course) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            "${ApiEndpoints.courseThumbnail}${course.thumbnail}",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.black26, size: 40)),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xAA000000),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _iconBtn(Icons.arrow_back,
                          () => Navigator.pop(context)),
                  const Spacer(),
                  _iconBtn(Icons.share_outlined, () {}),
                  const SizedBox(width: 8),
                  _iconBtn(
                    _isWishlisted
                        ? Icons.favorite
                        : Icons.favorite_border,
                        () => setState(
                            () => _isWishlisted = !_isWishlisted),
                    color:
                    _isWishlisted ? Colors.red : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CoursePreviewScreen(course: course))),
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5),
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 34),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              course.duration.isNotEmpty
                  ? course.duration
                  : "Preview",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab(Course course) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("About this course",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay')),
          const SizedBox(height: 10),
          Text(
            course.description.isNotEmpty
                ? course.description
                : "Join Arun's signature masterclass and transform your hobby into a professional career.",
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.6,
                fontFamily: 'Inter'),
          ),
          const SizedBox(height: 24),
          const Text("What you will learn",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay')),
          const SizedBox(height: 12),
          ..._learningPoints.map((p) => _learningItem(p)),
          const SizedBox(height: 24),
          _buildInstructorCard(course),
        ],
      ),
    );
  }

  Widget _learningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontFamily: 'Inter'))),
        ],
      ),
    );
  }

  Widget _buildInstructorCard(Course course) {
    final instructorName = course.instructor.isNotEmpty
        ? course.instructor
        : 'Arun Kumar';
    // Build avatar URL without hardcoding the domain
    final avatarUrl =
        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(instructorName)}&background=D4AF37&color=fff";

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstructorProfileScreen(
              instructor: Instructor(
                name: instructorName,
                title: 'Master Artist',
                imageUrl: avatarUrl,
                bio:
                'Founder of Arun Mehndi Studio, dedicated to preserving and innovating the art of henna.',
                totalCourses: 24,
                totalStudents: '12K+',
                rating: 4.9,
                courses: const [],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.gold.withOpacity(0.2),
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Instructor",
                      style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          fontFamily: 'Inter')),
                  Text(instructorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Inter')),
                  Text("Professional Mehndi Artist since 2012",
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.gold),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusTab() {
    if (_loadingModules) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator()));
    }

    final modules =
    _modules.isNotEmpty ? _modules : _fallbackModules;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Course Modules",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay')),
              Text("${modules.length} modules",
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontFamily: 'Inter')),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(modules.length,
                  (i) => _buildModuleCard(i, modules)),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
      int index, List<Map<String, dynamic>> modules) {
    final module = modules[index];
    final isExpanded = module["expanded"] as bool;
    final items = module["items"] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(
                    () => modules[index]["expanded"] = !isExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.gold.withOpacity(0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text("${index + 1}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              color: isExpanded
                                  ? AppColors.gold
                                  : Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(module["title"],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                fontFamily: 'Inter')),
                        Text("${items.length} Lessons",
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && items.isNotEmpty) ...[
            Divider(color: Colors.grey.shade100, height: 1),
            ...List.generate(items.length, (i) {
              final item = items[i] as Map;
              final isFree = item["free"] as bool? ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline,
                        color: isFree
                            ? AppColors.gold
                            : Colors.grey.shade400,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(item["title"]?.toString() ?? '',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                  color: isFree
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.grey.shade500)),
                          if ((item["duration"]?.toString() ??
                              '')
                              .isNotEmpty)
                            Text(
                                item["duration"].toString(),
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                    fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                    if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                          AppColors.gold.withOpacity(0.12),
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: const Text("FREE",
                            style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter')),
                      )
                    else
                      Icon(Icons.lock_outline,
                          color: Colors.grey.shade300,
                          size: 16),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEnrollBar(Course course, bool hasOldPrice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasOldPrice)
                Text("₹${course.oldPrice}",
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        fontFamily: 'Inter')),
              Text("₹${course.price}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                    fontFamily: 'PlayfairDisplay',
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _isEnrolled || _enrolling ? null : _enroll,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _isEnrolled
                      ? Colors.green
                      : AppColors.gold,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (_isEnrolled
                          ? Colors.green
                          : AppColors.gold)
                          .withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _enrolling
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2))
                      : Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEnrolled
                            ? Icons.check_circle
                            : Icons.arrow_forward,
                        color: Colors.white, size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEnrolled
                            ? "Already Enrolled"
                            : "Enroll Now",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(text,
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontFamily: 'Inter')),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border:
          Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  final List<String> _learningPoints = [
    "Advanced Symmetry Techniques for both hands",
    "Organic Cone Preparation for deep, dark stains",
    "Modern Fusion — Arabic & Rajasthani patterns",
    "Business of Mehndi Art — pricing & bookings",
  ];

  final List<Map<String, dynamic>> _fallbackModules = [
    {
      "title": "Basic Strokes & Elements",
      "expanded": false,
      "items": [
        {"title": "Introduction to Cones", "duration": "12:30", "free": true},
        {"title": "Lines, Dots & Teardrops", "duration": "25:10", "free": false},
      ],
    },
    {
      "title": "Intricate Patterns & Fillers",
      "expanded": false,
      "items": [],
    },
  ];
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) =>
      Container(color: Colors.white, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) =>
      false;
}