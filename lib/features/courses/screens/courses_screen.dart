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
  List<Course> courses = [];

  int page = 1;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  String selectedCategory = "All";
  String? selectedLevel;
  String search = "";
  String token = "";

  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // ✅ UI Name : API Value
  final Map<String, String?> categories = {
    "All": null,
    "Mehndi": "mehndi",
    "Beauty": "beauty",
    "Makeup": "makeup",
    "Nail Art": "nail_art",
  };

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    if (current >= maxScroll - 100 &&
        !isLoadingMore &&
        !isLoading &&
        hasMore) {
      loadMore();
    }
  }

  Future<void> _init() async {
    token = await StorageHelper.getToken() ?? "";
    await fetchCourses();
  }

  Future<void> fetchCourses() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isLoadingMore = false;
      page = 1;
      hasMore = true;
      courses = [];
    });

    try {
      final data = await CourseService.getCourses(
        token: token,
        category: categories[selectedCategory],
        level: selectedLevel,
        search: search.trim().isEmpty ? null : search.trim(),
        page: 1,
      );

      // ✅ Debug categories
      if (data.isNotEmpty) {
        debugPrint("📋 AVAILABLE CATEGORIES:");
        for (var c in data) {
          debugPrint("→ ${c.category}");
        }
      }

      if (!mounted) return;

      setState(() {
        courses = data;
        hasMore = data.length >= 10;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ FETCH ERROR: $e");

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || isLoading) return;

    setState(() => isLoadingMore = true);

    final nextPage = page + 1;

    try {
      final data = await CourseService.getCourses(
        token: token,
        category: categories[selectedCategory],
        level: selectedLevel,
        search: search.trim().isEmpty ? null : search.trim(),
        page: nextPage,
      );

      if (!mounted) return;

      setState(() {
        if (data.isEmpty || data.length < 10) {
          hasMore = false;
        }

        if (data.isNotEmpty) {
          courses.addAll(data);
          page = nextPage;
        }

        isLoadingMore = false;
      });
    } catch (e) {
      debugPrint("❌ LOAD MORE ERROR: $e");

      if (mounted) {
        setState(() => isLoadingMore = false);
      }
    }
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        selectedLevel: selectedLevel,
        onApply: (level) {
          setState(() {
            selectedLevel = level;
            search = "";
          });

          fetchCourses();
        },
        onClear: () {
          setState(() {
            selectedLevel = null;
          });

          fetchCourses();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
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

          // ✅ SEARCH
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Search courses...",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                if (_debounce?.isActive ?? false) {
                  _debounce!.cancel();
                }

                _debounce = Timer(
                  const Duration(milliseconds: 500),
                      () {
                    setState(() {
                      search = val.trim();
                      selectedCategory = "All";
                      selectedLevel = null;
                    });

                    fetchCourses();
                  },
                );
              },
            ),
          ),

          // ✅ CATEGORY CHIPS
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Divider(
                  color: Colors.grey.shade100,
                  height: 1,
                ),

                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {

                      final title =
                      categories.keys.elementAt(i);

                      final isSelected =
                          selectedCategory == title;

                      return GestureDetector(
                        onTap: () {
                          if (selectedCategory == title) return;

                          setState(() {
                            selectedCategory = title;
                            search = "";
                          });

                          fetchCourses();
                        },
                        child: Container(
                          margin:
                          const EdgeInsets.only(right: 8),
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.red
                                : Colors.grey.shade100,
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.red
                                  : Colors.grey.shade200,
                            ),
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

          const SizedBox(height: 8),

          // ✅ COURSE LIST
          Expanded(
            child: isLoading
                ? ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (_, __) =>
              const CourseCardShimmer(),
            )

                : courses.isEmpty

                ? Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.search_off,
                    color: Colors.grey.shade300,
                    size: 60,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "No courses found",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),

                  if (selectedCategory != "All")
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 8),
                      child: Text(
                        "Category: $selectedCategory",
                        style: TextStyle(
                          color:
                          Colors.grey.shade300,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            )

                : ListView.builder(
              controller: _scrollController,
              padding:
              const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                24,
              ),
              itemCount:
              courses.length +
                  (isLoadingMore ? 1 : 0),
              itemBuilder: (_, i) {

                if (i == courses.length) {
                  return const Padding(
                    padding:
                    EdgeInsets.symmetric(
                        vertical: 24),
                    child: Center(
                      child:
                      CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                return CourseCard(
                  course: courses[i],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}