import 'package:flutter/material.dart';
import '../../courses/models/course_model.dart';
import '../../courses/services/course_service.dart';
import '../../courses/screens/course_detail_screen.dart';
import '../../../core/helpers/storage_helper.dart';

class FeaturedCourses extends StatefulWidget {
  final VoidCallback? onSeeAll;

  const FeaturedCourses({super.key, this.onSeeAll});

  @override
  State<FeaturedCourses> createState() => _FeaturedCoursesState();
}

class _FeaturedCoursesState extends State<FeaturedCourses> {
  List<Course> courses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    try {
      final token = await StorageHelper.getToken() ?? "";
      final data = await CourseService.getCourses(
        token: token,
        page: 1,
      );
      if (mounted) {
        setState(() {
          courses = data.take(5).toList(); // ✅ sirf 5 show karo home pe
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("FEATURED COURSES ERROR: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ─── HEADER ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Featured Courses",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: widget.onSeeAll, // ✅ courses tab pe jaao
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── COURSE LIST ──────────────────────────────
          isLoading
              ? SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) => _shimmerCard(),
            ),
          )
              : courses.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text(
                "No courses available",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
              : SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              itemBuilder: (_, i) =>
                  _FeaturedCourseCard(course: courses[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHIMMER PLACEHOLDER ──────────────────────────────
  Widget _shimmerCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ─── FEATURED COURSE CARD ──────────────────────────────────
class _FeaturedCourseCard extends StatelessWidget {
  final Course course;

  const _FeaturedCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(course: course),
        ),
      ),
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: Image.network(
                    "https://api.aktuhub.in/api/uploads/courses/${course.thumbnail}",
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.black26, size: 28),
                      ),
                    ),
                  ),
                ),

                // Level badge
                if (course.level.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _levelColor(course.level),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.level,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Play icon
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.black87, size: 16),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Price
                  Text(
                    "₹${course.price}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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