import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'course_preview_screen.dart';
import '../../courses/models/course_model.dart';
// import '../../instructor/screens/instructor_profile_screen.dart';
import 'package:mehndi_student_app/features/instructor/screens/instructor_profile_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWishlisted = false;
  int _selectedTab = 1; // default: Syllabus

  // ─── Dummy syllabus data (replace with API data) ──────
  final List<Map<String, dynamic>> _modules = [
    {
      "title": "Basic Strokes & Elements",
      "lessons": 4,
      "duration": "1h 15m",
      "expanded": true,
      "items": [
        {"title": "Introduction to Cones", "duration": "12:30", "free": true},
        {"title": "Lines, Dots & Teardrops", "duration": "25:10", "free": false},
        {"title": "Vines & Leaves", "duration": "18:45", "free": false},
        {"title": "Spiral Patterns", "duration": "19:00", "free": false},
      ],
    },
    {
      "title": "Intricate Patterns & Fillers",
      "lessons": 6,
      "duration": "2h 45m",
      "expanded": false,
      "items": [],
    },
    {
      "title": "Bridal Figures & Portraits",
      "lessons": 8,
      "duration": "5h 20m",
      "expanded": false,
      "items": [],
    },
    {
      "title": "Symmetry & Layout Planning",
      "lessons": 6,
      "duration": "3h 10m",
      "expanded": false,
      "items": [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final hasOldPrice = course.oldPrice.isNotEmpty && course.oldPrice != "0";

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [

              // ─── VIDEO THUMBNAIL ─────────────────────
              SliverToBoxAdapter(
                child: _buildVideoHeader(course),
              ),

              // ─── COURSE INFO ─────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Badges row
                      Row(
                        children: [
                          _badge("Best Seller", const Color(0xFFD4AF37),
                              const Color(0xFFFFF8E1)),
                          const SizedBox(width: 8),
                          if (course.level.isNotEmpty)
                            _badge(
                              _capitalize(course.level),
                              Colors.black87,
                              Colors.grey.shade100,
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          height: 1.3,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Rating + Students
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFD4AF37), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            course.rating > 0
                                ? course.rating.toStringAsFixed(1)
                                : "4.8",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          Text(
                            " (${course.totalReviews > 0 ? course.totalReviews : "1.2k"})",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.people_outline,
                              size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            "${course.totalStudents > 0 ? course.totalStudents : "5.4k"} Enrolled",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${course.price}",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                          if (hasOldPrice) ...[
                            const SizedBox(width: 10),
                            Text(
                              "₹${course.oldPrice}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "50% OFF",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ─── TABS ─────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFD4AF37),
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: const Color(0xFFD4AF37),
                    indicatorWeight: 2,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "About"),
                      Tab(text: "Syllabus"),
                      Tab(text: "Reviews"),
                    ],
                  ),
                ),
              ),

              // ─── TAB CONTENT ─────────────────────────
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _selectedTab == 0
                      ? _buildAboutTab(course)
                      : _selectedTab == 1
                      ? _buildSyllabusTab()
                      : _buildReviewsTab(),
                ),
              ),

              // Bottom padding for enroll button
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // ─── STICKY ENROLL BUTTON ─────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildEnrollBar(course, hasOldPrice),
          ),
        ],
      ),
    );
  }

  // ─── VIDEO HEADER ──────────────────────────────────────
  Widget _buildVideoHeader(Course course) {
    return Stack(
      children: [
        // Thumbnail
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            "https://api.aktuhub.in/api/uploads/courses/${course.thumbnail}",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.image_not_supported,
                    color: Colors.black26, size: 40),
              ),
            ),
          ),
        ),

        // Gradient overlay
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

        // Top bar: back + share + wishlist
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _iconBtn(Icons.arrow_back, () => Navigator.pop(context)),
                  const Spacer(),
                  _iconBtn(Icons.share_outlined, () {}),
                  const SizedBox(width: 8),
                  _iconBtn(
                    _isWishlisted
                        ? Icons.favorite
                        : Icons.favorite_border,
                        () => setState(() => _isWishlisted = !_isWishlisted),
                    color: _isWishlisted ? Colors.red : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Play button
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoursePreviewScreen(course: course),
                ),
              ),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 34),
              ),
            ),
          ),
        ),

        // Duration badge
        Positioned(
          bottom: 10,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              course.duration.isNotEmpty ? course.duration : "Preview",
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

  // ─── ABOUT TAB ─────────────────────────────────────────
  Widget _buildAboutTab(Course course) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About this course",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.description.isNotEmpty
                ? course.description
                : "Join Arun's signature masterclass and transform your hobby into a professional career. From basic strokes to complex bridal layouts.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // What you'll learn
          const Text(
            "What you will learn",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 12),
          ..._learningPoints.map((point) => _learningItem(point)),

          const SizedBox(height: 24),

          // Instructor
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
          const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCard(Course course) {
    return GestureDetector(                          // ← NAYA: tap wrapper
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstructorProfileScreen(
              instructor: Instructor(
                name: course.instructor.isNotEmpty
                    ? course.instructor
                    : 'Arun Sir',
                title: 'Master Artist',
                imageUrl:
                'https://ui-avatars.com/api/?name=${course.instructor}&background=D4AF37&color=fff',
                bio:
                'Founder of Arun Mehndi Studio, I have dedicated my career to preserving and innovating the art of henna. Having trained thousands of students worldwide.',
                totalCourses: 24,
                totalStudents: '12K+',
                rating: 4.9,
                courses: const [],   // apna API data yahan dena baad mein
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
              backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
              backgroundImage: NetworkImage(
                "https://ui-avatars.com/api/?name=${course.instructor.isNotEmpty ? course.instructor : 'Arun Kumar'}&background=D4AF37&color=fff",
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Instructor",
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    course.instructor.isNotEmpty
                        ? course.instructor
                        : "Arun Kumar",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "Professional Mehndi Artist since 2012",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // ← NAYA: arrow icon
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Color(0xFFD4AF37)),
          ],
        ),
      ),
    );
  }

  // ─── SYLLABUS TAB ──────────────────────────────────────
  Widget _buildSyllabusTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Course Modules",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              Text(
                "24 Lessons • 12h 30m",
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_modules.length, (index) {
            return _buildModuleCard(index);
          }),
        ],
      ),
    );
  }

  Widget _buildModuleCard(int index) {
    final module = _modules[index];
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Module header
          GestureDetector(
            onTap: () {
              setState(() {
                _modules[index]["expanded"] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Number circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? const Color(0xFFD4AF37).withOpacity(0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isExpanded
                              ? const Color(0xFFD4AF37)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module["title"],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${module["lessons"]} Lessons • ${module["duration"]}",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
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

          // Lesson items
          if (isExpanded && items.isNotEmpty) ...[
            Divider(color: Colors.grey.shade100, height: 1),
            ...List.generate(items.length, (i) {
              final item = items[i] as Map;
              final isFree = item["free"] as bool;
              return _buildLessonItem(item, isFree);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonItem(Map item, bool isFree) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: isFree
                ? const Color(0xFFD4AF37)
                : Colors.grey.shade400,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isFree
                        ? const Color(0xFF1C1C1E)
                        : Colors.grey.shade500,
                  ),
                ),
                Text(
                  item["duration"],
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isFree)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "FREE",
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Icon(Icons.lock_outline,
                color: Colors.grey.shade300, size: 16),
        ],
      ),
    );
  }

  // ─── REVIEWS TAB ───────────────────────────────────────
  Widget _buildReviewsTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Rating summary
          Row(
            children: [
              Column(
                children: [
                  const Text(
                    "4.8",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay',
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                          (i) => Icon(
                        i < 4 ? Icons.star : Icons.star_half,
                        color: const Color(0xFFD4AF37),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "1.2k reviews",
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _ratingBar(5, 0.72),
                    _ratingBar(4, 0.18),
                    _ratingBar(3, 0.07),
                    _ratingBar(2, 0.02),
                    _ratingBar(1, 0.01),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 16),

          // Sample reviews
          ...[
            {
              "name": "Priya S.",
              "rating": 5,
              "time": "2 weeks ago",
              "comment":
              "Excellent course! Arun sir explains everything so clearly. My designs have improved a lot."
            },
            {
              "name": "Meera K.",
              "rating": 5,
              "time": "1 month ago",
              "comment":
              "Best mehndi course I've ever taken. The bridal module is especially detailed and helpful."
            },
          ].map((r) => _reviewCard(r)).toList(),
        ],
      ),
    );
  }

  Widget _ratingBar(int star, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$star",
              style:
              TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFD4AF37)),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                const Color(0xFFD4AF37).withOpacity(0.15),
                child: Text(
                  (r["name"] as String)[0],
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r["name"] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(r["time"] as String,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  r["rating"] as int,
                      (_) => const Icon(Icons.star,
                      color: Color(0xFFD4AF37), size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r["comment"] as String,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100),
        ],
      ),
    );
  }

  // ─── ENROLL BAR ────────────────────────────────────────
  Widget _buildEnrollBar(Course course, bool hasOldPrice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasOldPrice)
                Text(
                  "₹${course.oldPrice}",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                "₹${course.price}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                // TODO: payment/enroll logic
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Enroll Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────
  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
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
}

// ─── TAB BAR DELEGATE ──────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}