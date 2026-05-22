import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/helpers/storage_helper.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../widgets/course_card.dart';
import '../shimmer/course_card_shimmer.dart';
import '../widgets/filter_bottom_sheet.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _allCourses = [];

  /// Client-side filtering so no extra API calls needed
  List<Course> get _filteredCourses {
    List<Course> result = List.from(_allCourses);

    // 1. Category filter (case-insensitive)
    if (selectedCategory != "All") {
      result = result
          .where((c) =>
      c.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    // 2. Level filter
    // UI labels: Beginner / Intermediate / Pro
    // DB values: Basic / Medium / Advanced
    if (selectedLevel != null) {
      final normalised = _normalisedLevel(selectedLevel!);
      result = result
          .where((c) => _normalisedLevel(c.level) == normalised)
          .toList();
    }

    // 3. Search filter (title, description, instructor, category)
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result
          .where((c) =>
      c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.instructor.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  /// Normalise level strings so comparisons always work regardless of
  /// whether the API sends "Basic", "basic", "Beginner" etc.
  String _normalisedLevel(String level) {
    switch (level.toLowerCase()) {
      case "beginner":
      case "basic":
        return "basic";
      case "intermediate":
      case "medium":
        return "medium";
      case "pro":
      case "advanced":
        return "advanced";
      default:
        return level.toLowerCase();
    }
  }

  bool isLoading = true;
  bool hasError = false;
  String selectedCategory = "All";
  String? selectedLevel;
  String search = "";
  String token = "";

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> categoryLabels = [
    "All",
    "Mehndi",
    "Beauty",
    "Makeup",
    "Nail Art",
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    token = await StorageHelper.getToken() ?? "";
    await _fetchAllCourses();
  }

  Future<void> _fetchAllCourses() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final data = await CourseService.getCourses(
        token: token,
        page: 1,
      );

      if (!mounted) return;
      setState(() {
        _allCourses = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ FETCH ERROR: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => search = "");
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        selectedLevel: selectedLevel,
        onApply: (level) => setState(() => selectedLevel = level),
        onClear: () => setState(() => selectedLevel = null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filteredCourses;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Courses",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _openFilter,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    Icons.tune,
                    color:
                    selectedLevel != null ? Colors.red : Colors.black54,
                    size: 20,
                  ),
                ),
              ),
              if (selectedLevel != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87, fontFamily: 'Inter'),
              decoration: InputDecoration(
                hintText: "Search courses...",
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontFamily: 'Inter'),
                prefixIcon:
                Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: search.isNotEmpty
                    ? GestureDetector(
                  onTap: _clearSearch,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.black54, size: 16),
                  ),
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => search = val),
            ),
          ),

          // ── CATEGORY CHIPS ──────────────────────────────
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Divider(color: Colors.grey.shade100, height: 1),
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: categoryLabels.length,
                    itemBuilder: (_, i) {
                      final title = categoryLabels[i];
                      final isSelected = selectedCategory == title;
                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedCategory = title;
                          search = "";
                          _searchController.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.red
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.red
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                                : [],
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Active filter indicator ─────────────────────
          if (selectedCategory != "All" ||
              selectedLevel != null ||
              search.isNotEmpty)
            Container(
              color: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    "${courses.length} results",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontFamily: 'Inter'),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = "All";
                        selectedLevel = null;
                        search = "";
                      });
                      _searchController.clear();
                    },
                    child: const Text(
                      "Clear All",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── COURSE LIST ─────────────────────────────────
          Expanded(
            child: isLoading
                ? ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (_, __) => const CourseCardShimmer(),
            )
                : hasError
                ? _buildError()
                : courses.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              onRefresh: _fetchAllCourses,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                    16, 4, 16, 24),
                itemCount: courses.length,
                itemBuilder: (_, i) =>
                    CourseCard(course: courses[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.grey.shade300, size: 60),
          const SizedBox(height: 12),
          Text(
            "Failed to load courses",
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontFamily: 'Inter'),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetchAllCourses,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Retry",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.grey.shade300, size: 60),
          const SizedBox(height: 12),
          Text(
            "No courses found",
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontFamily: 'Inter'),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = "All";
                selectedLevel = null;
                search = "";
              });
              _searchController.clear();
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Show All Courses",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}