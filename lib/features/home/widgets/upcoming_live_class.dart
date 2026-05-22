import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/storage_helper.dart';

// ─── MODEL ───────────────────────────────────────────────
class LiveClass {
  final String id;
  final String title;
  final String description;
  final String startTime;
  final String meetLink;
  final String instructor;

  LiveClass({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.meetLink,
    required this.instructor,
  });

  factory LiveClass.fromJson(Map<String, dynamic> json) {
    return LiveClass(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      meetLink: json['meet_link']?.toString() ?? '',
      instructor: json['instructor_name']?.toString() ??
          json['instructor']?.toString() ?? '',
    );
  }

  String get formattedTime {
    if (startTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(startTime);
      final now = DateTime.now();
      final diff = dt.difference(now);

      if (diff.isNegative) return 'Live Now';
      if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'In ${diff.inHours}h';
      // Show date
      final months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}, ${_pad(dt.hour)}:${_pad(dt.minute)}';
    } catch (_) {
      return startTime.length > 10 ? startTime.substring(0, 10) : startTime;
    }
  }

  bool get isLiveNow {
    if (startTime.isEmpty) return false;
    try {
      final dt = DateTime.parse(startTime);
      final diff = DateTime.now().difference(dt);
      // Consider live if started within last 2 hours
      return diff.inMinutes >= 0 && diff.inHours < 2;
    } catch (_) {
      return false;
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── WIDGET ───────────────────────────────────────────────
class UpcomingLiveClass extends StatefulWidget {
  const UpcomingLiveClass({super.key});

  @override
  State<UpcomingLiveClass> createState() => _UpcomingLiveClassState();
}

class _UpcomingLiveClassState extends State<UpcomingLiveClass> {
  List<LiveClass> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final token = await StorageHelper.getToken() ?? '';
      final res = await http.get(
        Uri.parse(
            "https://api.aktuhub.in/api/live?type=upcoming"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data =
        body is Map && body['data'] is List
            ? body['data']
            : body is List
            ? body
            : [];
        if (mounted) {
          setState(() {
            _classes = data
                .map((e) => LiveClass.fromJson(e as Map<String, dynamic>))
                .toList();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("LIVE CLASS ERROR: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    if (_classes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Upcoming Live Classes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        ..._classes.take(3).map((lc) => _LiveCard(liveClass: lc)),
      ],
    );
  }
}

class _LiveCard extends StatelessWidget {
  final LiveClass liveClass;
  const _LiveCard({required this.liveClass});

  @override
  Widget build(BuildContext context) {
    final isLive = liveClass.isLiveNow;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A0A), Color(0xFF0A0A1A)],
        ),
      ),
      child: Row(
        children: [
          // Left: icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isLive
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLive ? Icons.live_tv : Icons.videocam_outlined,
              color: isLive ? AppColors.primary : AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Middle: info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LIVE badge or time
                Row(
                  children: [
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.circle,
                                size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "LIVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          liveClass.formattedTime,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  liveClass.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (liveClass.instructor.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    "with ${liveClass.instructor}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isLive
                        ? "Joining: ${liveClass.title}"
                        : "Reminder set for ${liveClass.formattedTime}",
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                isLive ? AppColors.primary : AppColors.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isLive ? "Join" : "Remind",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}