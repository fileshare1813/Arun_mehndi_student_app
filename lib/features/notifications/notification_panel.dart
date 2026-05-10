import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

// ─── MODEL ───────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  bool isRead;
  final String timeAgo;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timeAgo,
  });
}

// ─── DUMMY DATA ───────────────────────────────────────────
List<AppNotification> _notifications = [
  AppNotification(
    id: '1',
    title: 'Live Class Starting Now!',
    message: 'Arabic Mehndi Fusion with Arun Sir is live. Join now!',
    type: 'live',
    isRead: false,
    timeAgo: 'Just now',
  ),
  AppNotification(
    id: '2',
    title: 'Special Offer — 30% Off',
    message: 'Bridal Mehndi Masterclass is now 30% off. Limited time only!',
    type: 'offer',
    isRead: false,
    timeAgo: '1h ago',
  ),
  AppNotification(
    id: '3',
    title: 'New Course Added',
    message: 'Rajasthani Bridal Mehndi is now available. Enroll today.',
    type: 'course',
    isRead: false,
    timeAgo: '3h ago',
  ),
  AppNotification(
    id: '4',
    title: 'Enrollment Confirmed',
    message: 'You are enrolled in Basic Mehndi Strokes. Start learning!',
    type: 'system',
    isRead: true,
    timeAgo: '1d ago',
  ),
  AppNotification(
    id: '5',
    title: 'Certificate Ready',
    message: 'Your certificate for Arabic Mehndi is ready to download.',
    type: 'system',
    isRead: true,
    timeAgo: '2d ago',
  ),
];

// ─── BELL BUTTON ─────────────────────────────────────────
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {

  int get _unread => _notifications.where((n) => !n.isRead).length;

  void _openPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationPanel(
        onChanged: () => setState(() {}),
      ),
    ).then((_) => setState(() {}));
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none,
                color: Colors.black87, size: 22),
            if (_unread > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _unread > 9 ? '9+' : '$_unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
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

// ─── PANEL (Bottom Sheet) ─────────────────────────────────
class _NotificationPanel extends StatefulWidget {
  final VoidCallback onChanged;

  const _NotificationPanel({required this.onChanged});

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {

  int get _unread => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    widget.onChanged();
  }

  void _markRead(String id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.isRead = true;
    });
    widget.onChanged();
  }

  void _remove(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    widget.onChanged();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'live':   return AppColors.primary;
      case 'offer':  return AppColors.gold;
      case 'course': return Colors.blue;
      default:       return Colors.teal;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'live':   return Icons.live_tv_rounded;
      case 'offer':  return Icons.local_offer_rounded;
      case 'course': return Icons.menu_book_rounded;
      default:       return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return Container(
      height: sh * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [

          // ── Handle ──
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 10),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: AppFonts.display,
                  ),
                ),
                const SizedBox(width: 8),
                if (_unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_unread new',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(color: Colors.grey.shade100, height: 1),

          // ── List ──
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmpty()
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.grey.shade100,
                height: 1,
                indent: 70,
                endIndent: 16,
              ),
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _remove(n.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.shade50,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                  child: _NotifTile(
                    notification: n,
                    color: _typeColor(n.type),
                    icon: _typeIcon(n.type),
                    onTap: () => _markRead(n.id),
                  ),
                );
              },
            ),
          ),

          // ── Swipe hint ──
          if (_notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 6),
              child: Text(
                'Swipe left to remove',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontFamily: AppFonts.body,
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
          Icon(Icons.notifications_off_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'No notifications',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontFamily: AppFonts.body,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TILE ────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isUnread
                                ? Colors.black87
                                : Colors.black54,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 11,
                      color: Colors.grey.shade400,
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
}