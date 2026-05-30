import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

import '../../widgets/side_drawer.dart';
import '../../models/user_model.dart';
import '../../core/helpers/storage_helper.dart';
import '../../core/api/api_endpoints.dart';
import '../courses/models/course_model.dart';
import '../courses/services/course_service.dart';
import '../courses/screens/course_detail_screen.dart';
import '../instructor/screens/instructor_profile_screen.dart';

import 'widgets/home_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/offer_banner.dart';
import 'widgets/categories_section.dart';
import 'widgets/featured_courses.dart';
import 'widgets/upcoming_live_class.dart';
import '../notifications/notification_panel.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSeeAllCourses;

  const HomeScreen({super.key, this.onSeeAllCourses});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? currentUser;

  String searchQuery = "";
  bool isSearching = false;

  List<Course> searchedCourses = [];
  List<String> matchedCategories = [];
  List<InstructorResult> instructors = [];

  bool loadingSearch = false;
  Timer? _debounce;

  final List<String> allCategories = [
    "Mehndi",
    "Beauty",
    "Makeup",
    "Nail Art",
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userJson = await StorageHelper.getUser();
    if (userJson != null && mounted) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() => currentUser = UserModel.fromJson(userMap));
      } catch (e) {
        debugPrint("loadUser error: $e");
      }
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        clearSearch();
        return;
      }
      setState(() {
        searchQuery = trimmed;
        isSearching = true;
      });
      _runSearch(trimmed);
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    setState(() {
      searchQuery = "";
      isSearching = false;
      searchedCourses = [];
      matchedCategories = [];
      instructors = [];
      loadingSearch = false;
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => loadingSearch = true);

    try {
      final token = await StorageHelper.getToken() ?? "";
      final q = query.toLowerCase();

      final courses = await CourseService.getCourses(
        token: token,
        search: query,
        page: 1,
      );

      final catMatches = allCategories
          .where((c) => c.toLowerCase().contains(q))
          .toList();

      final Map<String, List<Course>> instructorMap = {};
      for (final c in courses) {
        if (c.instructor.isNotEmpty &&
            c.instructor.toLowerCase().contains(q)) {
          instructorMap.putIfAbsent(c.instructor, () => []).add(c);
        }
      }

      if (!mounted) return;
      setState(() {
        searchedCourses = courses;
        matchedCategories = catMatches;
        instructors = instructorMap.entries
            .map((e) =>
            InstructorResult(name: e.key, courses: e.value))
            .toList();
        loadingSearch = false;
      });
    } catch (e) {
      debugPrint("SEARCH ERROR: $e");
      if (mounted) setState(() => loadingSearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      drawer: const SideDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8),
              ],
            ),
            child: IconButton(
              icon:
              const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        actions: const [NotificationBell()],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  HomeHeader(user: currentUser!),
                  const SizedBox(height: 10),
                  HomeSearchBar(
                    onChanged: onSearchChanged,
                    onClear: clearSearch,
                    query: searchQuery,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: isSearching
                  ? _buildSearchResults()
                  : _buildHomeContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const OfferBanner(),
          CategoriesSection(
            onSeeAll: widget.onSeeAllCourses,
            onCategoryTap: onSearchChanged,
          ),
          FeaturedCourses(onSeeAll: widget.onSeeAllCourses),
          const UpcomingLiveClass(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (loadingSearch) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.red));
    }

    final hasResults = searchedCourses.isNotEmpty ||
        matchedCategories.isNotEmpty ||
        instructors.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "No results found for \"$searchQuery\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  fontFamily: 'Inter'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: clearSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Clear Search",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter')),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (matchedCategories.isNotEmpty) ...[
            _sectionHeader("Categories", null),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                itemCount: matchedCategories.length,
                itemBuilder: (_, i) {
                  final cat = matchedCategories[i];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        searchQuery = cat;
                        matchedCategories = [];
                        instructors = [];
                      });
                      _runSearch(cat);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(cat,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (instructors.isNotEmpty) ...[
            _sectionHeader("Instructors", null),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                itemCount: instructors.length,
                itemBuilder: (_, i) =>
                    _InstructorChip(instructor: instructors[i]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (searchedCourses.isNotEmpty) ...[
            _sectionHeader(
                "Courses", "${searchedCourses.length} results"),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding:
              const EdgeInsets.symmetric(horizontal: 16),
              itemCount: searchedCourses.length,
              itemBuilder: (_, i) =>
                  _SearchCourseCard(course: searchedCourses[i]),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Inter',
              )),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontFamily: 'Inter')),
          ],
        ],
      ),
    );
  }
}

// ── InstructorResult Model ─────────────────────────────────
class InstructorResult {
  final String name;
  final List<Course> courses;

  InstructorResult({required this.name, required this.courses});
}

// ── Instructor Chip Widget ─────────────────────────────────
class _InstructorChip extends StatelessWidget {
  final InstructorResult instructor;
  const _InstructorChip({required this.instructor});

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        "https://ui-avatars.com/api/?name=${Uri.encodeComponent(instructor.name)}&background=D4AF37&color=fff";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstructorProfileScreen(
              instructor: Instructor(
                name: instructor.name,
                title: 'Mehndi Artist',
                imageUrl: avatarUrl,
                bio:
                'Professional Mehndi Artist with expertise in bridal and traditional designs.',
                totalCourses: instructor.courses.length,
                totalStudents: '1K+',
                rating: 4.8,
                courses: instructor.courses
                    .take(3)
                    .map((c) => InstructorCourse(
                  title: c.title,
                  imageUrl:
                  "${ApiEndpoints.courseThumbnail}${c.thumbnail}",
                  lessons: c.totalLessons,
                  duration: c.duration,
                  price: '₹${c.price}',
                  badge: 'POPULAR',
                ))
                    .toList(),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
              const Color(0xFFD4AF37).withOpacity(0.15),
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(height: 8),
            Text(
              instructor.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search Course Card ────────────────────────────────────
class _SearchCourseCard extends StatelessWidget {
  final Course course;
  const _SearchCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  CourseDetailScreen(course: course))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "${ApiEndpoints.courseThumbnail}${course.thumbnail}",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.black26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (course.category.isNotEmpty)
                    Text(
                      course.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (course.instructor.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(course.instructor,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontFamily: 'Inter')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${course.price}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: 'Inter',
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: const Text('Enroll',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}