import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Instructor Model ─────────────────────────────────────
class Instructor {
  final String name;
  final String title;
  final String imageUrl;
  final String bio;
  final int totalCourses;
  final String totalStudents;
  final double rating;
  final List<InstructorCourse> courses;

  const Instructor({
    required this.name,
    required this.title,
    required this.imageUrl,
    required this.bio,
    required this.totalCourses,
    required this.totalStudents,
    required this.rating,
    required this.courses,
  });
}

class InstructorCourse {
  final String title;
  final String imageUrl;
  final int lessons;
  final String duration;
  final String price;
  final String badge;

  const InstructorCourse({
    required this.title,
    required this.imageUrl,
    required this.lessons,
    required this.duration,
    required this.price,
    required this.badge,
  });
}

// ─── Screen ───────────────────────────────────────────────
class InstructorProfileScreen extends StatefulWidget {
  final Instructor instructor;

  const InstructorProfileScreen({super.key, required this.instructor});

  @override
  State<InstructorProfileScreen> createState() =>
      _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  bool _isFollowing = false;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _bgLight = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final inst = widget.instructor;

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ─── App Bar ─────────────────────────────
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF1C1C1E), size: 20),
                  ),
                ),
                title: const Text(
                  'Instructor Profile',
                  style: TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
                actions: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // TODO: Share logic
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.share_outlined,
                            color: Color(0xFF1C1C1E), size: 20),
                      ),
                    ),
                  ),
                ],
              ),

              // ─── Profile Header ───────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      // Avatar with verified badge
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _gold, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: inst.imageUrl.startsWith('http')
                                  ? Image.network(
                                inst.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(inst.name),
                              )
                                  : _avatarFallback(inst.name),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _gold,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.verified,
                                color: Colors.white, size: 16),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        inst.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Title badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _gold.withOpacity(0.3)),
                        ),
                        child: Text(
                          inst.title.toUpperCase(),
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Bio subtitle
                      Text(
                        inst.bio.split('.').first + '.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Follow + Message buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() => _isFollowing = !_isFollowing);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isFollowing
                                      ? Colors.white
                                      : _gold,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _gold,
                                    width: _isFollowing ? 1.5 : 0,
                                  ),
                                  boxShadow: _isFollowing
                                      ? []
                                      : [
                                    BoxShadow(
                                      color: _gold.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _isFollowing ? 'Following ✓' : 'Follow',
                                    style: TextStyle(
                                      color: _isFollowing
                                          ? _gold
                                          : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // TODO: Message logic
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Icon(Icons.mail_outline,
                                  color: Colors.grey.shade600, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // ─── Stats Row ────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      _statCard('Courses',
                          inst.totalCourses.toString(), Icons.play_lesson),
                      const SizedBox(width: 10),
                      _statCard(
                          'Students', inst.totalStudents, Icons.people),
                      const SizedBox(width: 10),
                      _statCard('Rating',
                          inst.rating.toStringAsFixed(1), Icons.star),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // ─── About Section ────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        inst.bio,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Social Icons
                      Row(
                        children: [
                          _socialIcon(Icons.language, () {}),
                          const SizedBox(width: 12),
                          _socialIcon(Icons.camera_alt_outlined, () {}),
                          const SizedBox(width: 12),
                          _socialIcon(Icons.play_circle_outline, () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // ─── Courses Header ───────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Courses by ${inst.name.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: _gold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Courses List ─────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final c = inst.courses[index];
                    final isLast = index == inst.courses.length - 1;
                    return Container(
                      color: Colors.white,
                      padding: EdgeInsets.fromLTRB(
                          16, 0, 16, isLast ? 100 : 0),
                      child: _courseCard(c, isLast),
                    );
                  },
                  childCount: inst.courses.length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stat Card ─────────────────────────────────────────
  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
                if (label == 'Rating') ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.star, color: _gold, size: 14),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Social Icon Button ────────────────────────────────
  Widget _socialIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: _gold.withOpacity(0.2)),
        ),
        child: Icon(icon, color: _gold, size: 20),
      ),
    );
  }

  // ─── Course Card ──────────────────────────────────────
  Widget _courseCard(InstructorCourse course, bool isLast) {
    final badgeColors = _badgeStyle(course.badge);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          // TODO: Navigate to course detail
        },
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 110,
                child: course.imageUrl.startsWith('http')
                    ? Image.network(
                  course.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: _gold.withOpacity(0.1)),
                )
                    : Container(color: _gold.withOpacity(0.1)),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          height: 1.3,
                        ),
                      ),

                      // Meta
                      Text(
                        '${course.lessons} Lessons • ${course.duration}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),

                      // Price + Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            course.price,
                            style: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColors.$1,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.badge,
                              style: TextStyle(
                                color: badgeColors.$2,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Avatar Fallback ─────────────────────────────────
  Widget _avatarFallback(String name) {
    return Container(
      color: _gold.withOpacity(0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: _gold,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── Badge Style ──────────────────────────────────────
  (Color, Color) _badgeStyle(String badge) {
    switch (badge.toUpperCase()) {
      case 'BESTSELLER':
        return (const Color(0xFFFFF8E1), const Color(0xFFD4AF37));
      case 'POPULAR':
        return (Colors.blue.shade50, Colors.blue.shade700);
      case 'INTERMEDIATE':
        return (Colors.grey.shade200, Colors.grey.shade600);
      case 'NEW':
        return (Colors.green.shade50, Colors.green.shade700);
      default:
        return (Colors.grey.shade100, Colors.grey.shade600);
    }
  }
}