import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/storage_helper.dart';

// ─── MODEL ───────────────────────────────────────────────
class Review {
  final String name;
  final double rating;
  final String comment;
  final String createdAt;

  Review({
    required this.name,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      name: json['name']?.toString() ?? 'Student',
      rating:
      double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      comment: json['review']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  String get timeAgo {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays < 1) return 'Today';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
      return '${(diff.inDays / 365).floor()}y ago';
    } catch (_) {
      return '';
    }
  }
}

// ─── REVIEWS WIDGET ───────────────────────────────────────
class CourseReviewsTab extends StatefulWidget {
  final int courseId;

  const CourseReviewsTab({super.key, required this.courseId});

  @override
  State<CourseReviewsTab> createState() => _CourseReviewsTabState();
}

class _CourseReviewsTabState extends State<CourseReviewsTab> {
  List<Review> _reviews = [];
  double _avgRating = 0.0;
  bool _loading = true;
  bool _submitting = false;

  // Submit review
  int _myRating = 5;
  final _commentCtrl = TextEditingController();
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse(
            "https://api.aktuhub.in/api/reviews?course_id=${widget.courseId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (mounted) {
          setState(() {
            _reviews = (data['reviews'] as List? ?? [])
                .map((e) => Review.fromJson(e as Map<String, dynamic>))
                .toList();
            _avgRating =
                double.tryParse(data['rating']?.toString() ?? '0') ??
                    0.0;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("REVIEWS ERROR: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a review")),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.post(
        Uri.parse("https://api.aktuhub.in/api/reviews"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "course_id": widget.courseId,
          "rating": _myRating,
          "review": _commentCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        _commentCtrl.clear();
        setState(() {
          _showForm = false;
          _submitting = false;
        });
        await _fetchReviews();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Review submitted!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(body['message'] ?? "Failed to submit")),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Server error. Please try again.")),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Rating Summary ──────────────────────────
          Row(
            children: [
              Column(
                children: [
                  Text(
                    _avgRating > 0
                        ? _avgRating.toStringAsFixed(1)
                        : "—",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PlayfairDisplay',
                      color: AppColors.gold,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                          (i) => Icon(
                        i < _avgRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.gold,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_reviews.length} review${_reviews.length == 1 ? '' : 's'}",
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = _reviews
                        .where((r) => r.rating.round() == star)
                        .length;
                    final fraction = _reviews.isEmpty
                        ? 0.0
                        : count / _reviews.length;
                    return _ratingBar(star, fraction);
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Write Review Button ─────────────────────
          GestureDetector(
            onTap: () => setState(() => _showForm = !_showForm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _showForm
                    ? Colors.grey.shade100
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _showForm
                      ? Colors.grey.shade200
                      : AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showForm ? Icons.close : Icons.rate_review_outlined,
                    color: _showForm
                        ? Colors.grey
                        : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showForm ? "Cancel" : "Write a Review",
                    style: TextStyle(
                      color: _showForm
                          ? Colors.grey
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Review Form ─────────────────────────────
          if (_showForm) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Rating",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _myRating = star),
                        child: Padding(
                          padding:
                          const EdgeInsets.only(right: 6),
                          child: Icon(
                            star <= _myRating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.gold,
                            size: 30,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: 14, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      hintText: "Share your experience...",
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontFamily: 'Inter'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                      _submitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2),
                      )
                          : const Text("Submit Review",
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter')),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 12),

          // ── Reviews List ────────────────────────────
          if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No reviews yet. Be the first!",
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter'),
                ),
              ),
            )
          else
            ..._reviews.map((r) => _reviewCard(r)),
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
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: 'Inter')),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Review r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.gold.withOpacity(0.15),
                child: Text(
                  r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFamily: 'Inter')),
                    if (r.timeAgo.isNotEmpty)
                      Text(r.timeAgo,
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontFamily: 'Inter')),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(
                    i < r.rating.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.gold,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
                fontFamily: 'Inter',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100),
        ],
      ),
    );
  }
}