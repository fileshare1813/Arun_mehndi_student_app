import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/helpers/storage_helper.dart';
import '../../../core/api/api_endpoints.dart';

// ─── MODEL ───────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  bool isRead;
  final String timeAgo;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timeAgo,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      isRead: (json['is_read'] == 1 || json['is_read'] == true),
      createdAt: json['created_at']?.toString() ?? '',
      timeAgo: _timeAgo(json['created_at']?.toString() ?? ''),
    );
  }

  static String _timeAgo(String createdAt) {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}

// ─── API SERVICE ──────────────────────────────────────────
class NotificationService {
  static Future<List<AppNotification>> getNotifications() async {
    final token = await StorageHelper.getToken();
    if (token == null) return [];

    final res = await http.get(
      Uri.parse(ApiEndpoints.notifications),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> data;
      if (body is Map && body['data'] is List) {
        data = body['data'];
      } else if (body is List) {
        data = body;
      } else {
        return [];
      }
      return data
          .map((e) {
        try {
          return AppNotification.fromJson(
              e as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      })
          .whereType<AppNotification>()
          .toList();
    }
    return [];
  }

  static Future<bool> markRead(String id) async {
    final token = await StorageHelper.getToken();
    if (token == null) return false;

    final res = await http.post(
      Uri.parse(ApiEndpoints.notifications),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"id": id}),
    ).timeout(const Duration(seconds: 10));

    return res.statusCode == 200;
  }
}

// ─── BELL BUTTON ─────────────────────────────────────────
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final list = await NotificationService.getNotifications();
      if (mounted) {
        setState(() =>
        _unreadCount = list.where((n) => !n.isRead).length);
      }
    } catch (_) {}
  }

  void _openPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _NotificationPanel(onChanged: _loadUnreadCount),
    ).then((_) => _loadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPanel,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 8),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none,
                color: Colors.black87, size: 22),
            if (_unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── PANEL ────────────────────────────────────────────────
class _NotificationPanel extends StatefulWidget {
  final VoidCallback onChanged;
  const _NotificationPanel({required this.onChanged});

  @override
  State<_NotificationPanel> createState() =>
      _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final list = await NotificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  int get _unread => _notifications.where((n) => !n.isRead).length;

  Future<void> _markRead(String id) async {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) _notifications[idx].isRead = true;
    });
    widget.onChanged();
    await NotificationService.markRead(id);
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    setState(() {
      for (final n in _notifications) n.isRead = true;
    });
    widget.onChanged();
    for (final n in unread) await NotificationService.markRead(n.id);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'live': return AppColors.primary;
      case 'offer': return AppColors.gold;
      case 'course': return Colors.blue;
      default: return Colors.teal;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'live': return Icons.live_tv_rounded;
      case 'offer': return Icons.local_offer_rounded;
      case 'course': return Icons.menu_book_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    return Container(
      height: sh * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 38, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 10),
            child: Row(
              children: [
                Text('Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: AppFonts.display,
                    )),
                const SizedBox(width: 8),
                if (_unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_unread new',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                const Spacer(),
                if (_unread > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Mark all read',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: Colors.black45, size: 20),
                  onPressed: _fetch,
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade100, height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? _buildError()
                : _notifications.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    vertical: 6),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.grey.shade100,
                  height: 1, indent: 70, endIndent: 16,
                ),
                itemBuilder: (_, i) {
                  final n = _notifications[i];
                  return _NotifTile(
                    notification: n,
                    color: _typeColor(n.type),
                    icon: _typeIcon(n.type),
                    onTap: () => _markRead(n.id),
                  );
                },
              ),
            ),
          ),
          if (!_loading && _notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 6),
              child: Text('Pull down to refresh',
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontFamily: AppFonts.body)),
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
          Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text('Failed to load notifications',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontFamily: AppFonts.body)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _fetch,
            child: const Text('Retry',
                style: TextStyle(color: AppColors.primary)),
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
          Icon(Icons.notifications_off_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text('No notifications yet',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontFamily: AppFonts.body)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notification;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _NotifTile({
    required this.notification,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.primary.withOpacity(0.04)
            : Colors.white,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isUnread
                                  ? Colors.black87
                                  : Colors.black54,
                            )),
                      ),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notification.message,
                      style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (notification.timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(notification.timeAgo,
                        style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 11,
                            color: Colors.grey.shade400)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}