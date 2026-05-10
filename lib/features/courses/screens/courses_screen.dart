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
  // ── All courses from API (unfiltered) ─────────────────
  List<Course> _allCourses = [];

  // ── Filtered list shown on screen ─────────────────────
  List<Course> get _filteredCourses {
    List<Course> result = List.from(_allCourses);

    // 1. Category filter
    if (selectedCategory != "All") {
      result = result
          .where((c) =>
      c.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    // 2. Level filter
    if (selectedLevel != null) {
      final levelMap = {
        "Beginner": "basic",
        "Intermediate": "medium",
        "Pro": "advanced",
      };
      final apiLevel = levelMap[selectedLevel!]?.toLowerCase();
      result = result
          .where((c) => c.level.toLowerCase() == (apiLevel ?? selectedLevel!.toLowerCase()))
          .toList();
    }

    // 3. Search filter
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

  bool isLoading = true;
  String selectedCategory = "All";
  String? selectedLevel;
  String search = "";
  String token = "";

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    token = await StorageHelper.getToken() ?? "";
    await _fetchAllCourses();
  }

  // ── Fetch ALL courses once ─────────────────────────────
  Future<void> _fetchAllCourses() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // No category/level/search — fetch all
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
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
                    color: selectedLevel != null ? Colors.red : Colors.black54,
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
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Search courses...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: search.isNotEmpty
                    ? GestureDetector(
                  onTap: _clearSearch,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 16,
                    ),
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
              onChanged: (val) {
                setState(() => search = val);
                // Debounce not needed since filtering is local
              },
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
                    _activeFilterText(courses.length),
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
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
                : courses.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      color: Colors.grey.shade300, size: 60),
                  const SizedBox(height: 12),
                  Text(
                    "No courses found",
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Show All Courses",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: courses.length,
              itemBuilder: (_, i) =>
                  CourseCard(course: courses[i]),
            ),
          ),
        ],
      ),
    );
  }

  String _activeFilterText(int count) {
    final parts = <String>[];
    if (selectedCategory != "All") parts.add(selectedCategory);
    if (selectedLevel != null) parts.add(selectedLevel!);
    if (search.isNotEmpty) parts.add('"$search"');
    return "$count results";
  }
}