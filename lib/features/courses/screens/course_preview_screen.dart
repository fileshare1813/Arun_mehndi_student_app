import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../courses/models/course_model.dart';
import 'package:mehndi_student_app/features/instructor/screens/instructor_profile_screen.dart';
class CoursePreviewScreen extends StatefulWidget {
  final Course course;

  const CoursePreviewScreen({super.key, required this.course});

  @override
  State<CoursePreviewScreen> createState() => _CoursePreviewScreenState();
}

class _CoursePreviewScreenState extends State<CoursePreviewScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ─── VIDEO PLAYER ───────────────────────
                _buildVideoPlayer(course),

                // ─── CONTENT ────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Badges
                      Row(
                        children: [
                          _badge("BESTSELLER"),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Color(0xFFD4AF37), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "4.9",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                " (2.1k reviews)",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
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

                      const SizedBox(height: 10),

                      // Description
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

                      const SizedBox(height: 28),

                      // ─── WHAT YOU'LL LEARN ────────────
                      _sectionTitle("What you will learn"),
                      const SizedBox(height: 14),

                      ..._learningPoints.map(
                            (point) => _learningItem(
                          point["title"]!,
                          point["subtitle"]!,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ─── INSTRUCTOR ───────────────────
                      _sectionTitle("Instructor"),
                      const SizedBox(height: 14),
                      _buildInstructorCard(course),

                    ],
                  ),
                ),

                // Bottom spacing for sticky bar
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ─── STICKY BOTTOM BAR ──────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(course, hasOldPrice),
          ),
        ],
      ),
    );
  }

  // ─── VIDEO PLAYER ────────────────────────────────────
  Widget _buildVideoPlayer(Course course) {
    return Stack(
      children: [
        // Thumbnail with dark overlay
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Image.network(
                "https://api.aktuhub.in/api/uploads/courses/${course.thumbnail}",
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x55000000),
                      Colors.transparent,
                      Color(0xBB000000),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconBtn(
                      Icons.arrow_back, () => Navigator.pop(context)),
                  // Title
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            "Arun Mehndi Studio",
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _iconBtn(Icons.share_outlined, () {}),
                ],
              ),
            ),
          ),
        ),

        // Preview trailer badge
        Positioned(
          top: 52,
          right: 12,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Text(
              "PREVIEW TRAILER",
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        // Play button
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: () {
                setState(() => _isPlaying = !_isPlaying);
                HapticFeedback.lightImpact();
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Transform.scale(
                  scale: _isPlaying ? 1.0 : _pulseAnimation.value,
                  child: child,
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Progress bar at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Progress
              Stack(
                children: [
                  Container(
                    height: 3,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Container(
                    height: 3,
                    width: MediaQuery.of(context).size.width * 0.33,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x88D4AF37),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "01:12 / 03:45",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.settings,
                            color: Colors.white.withOpacity(0.8), size: 18),
                        const SizedBox(width: 12),
                        Icon(Icons.fullscreen,
                            color: Colors.white.withOpacity(0.8), size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── LEARNING ITEM ───────────────────────────────────
  Widget _learningItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── INSTRUCTOR CARD ─────────────────────────────────
  Widget _buildInstructorCard(Course course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.4),
                  width: 2),
            ),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                "https://ui-avatars.com/api/?name=Arun+Kumar&background=D4AF37&color=fff",
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "INSTRUCTOR",
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InstructorProfileScreen(
                    instructor: Instructor(
                      name: course.instructor.isNotEmpty
                          ? course.instructor
                          : "Arun Kumar",

                      title: "Professional Mehndi Artist",

                      imageUrl:
                      "https://ui-avatars.com/api/?name=Arun+Kumar&background=D4AF37&color=fff",

                      bio:
                      "Professional Mehndi Artist since 2012. Specialized in bridal, Arabic, and modern mehndi designs with thousands of students trained worldwide.",

                      totalCourses: 12,

                      totalStudents: "25K+",

                      rating: 4.9,

                      courses: [
                        InstructorCourse(
                          title: "Bridal Mehndi Masterclass",
                          imageUrl:
                          "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",

                          lessons: 45,
                          duration: "12h 30m",
                          price: "₹1999",
                          badge: "BESTSELLER",
                        ),

                        InstructorCourse(
                          title: "Arabic Mehndi Design Course",
                          imageUrl:
                          "https://images.unsplash.com/photo-1517841905240-472988babdf9",

                          lessons: 30,
                          duration: "8h 10m",
                          price: "₹1499",
                          badge: "POPULAR",
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },

            child: const Text(
              "View",
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────
  Widget _buildBottomBar(Course course, bool hasOldPrice) {
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
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                // TODO: payment logic
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
                    Icon(Icons.arrow_forward,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'PlayfairDisplay',
        color: Color(0xFF1C1C1E),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
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
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  final List<Map<String, String>> _learningPoints = [
    {
      "title": "Advanced Symmetry Techniques",
      "subtitle": "Master the mirror effect for both hands perfectly.",
    },
    {
      "title": "Organic Cone Preparation",
      "subtitle": "Learn to mix pure henna for deep, dark stains.",
    },
    {
      "title": "Modern Fusion Styles",
      "subtitle": "Combining Arabic and Rajasthani bridal patterns.",
    },
    {
      "title": "Business of Mehndi Art",
      "subtitle": "How to price your services and handle bridal bookings.",
    },
  ];
}