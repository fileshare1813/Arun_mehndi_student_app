import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/helpers/storage_helper.dart';
import '../models/user_model.dart';
import '../features/auth/login_screen.dart';
import '../features/profile/profile_screen.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({super.key});

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  UserModel? currentUser;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userJson = await StorageHelper.getUser();
    if (userJson != null && mounted) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          currentUser = UserModel.fromJson(map);
          _loading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await StorageHelper.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1405),
        child: SafeArea(
          child: Column(
            children: [
              // ── User Header ──────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                        AppColors.gold.withOpacity(0.2),
                        backgroundImage: currentUser?.profileImage !=
                            null &&
                            currentUser!.profileImage!.isNotEmpty
                            ? NetworkImage(
                            "https://api.aktuhub.in/uploads/profile_images/${currentUser!.profileImage}")
                            : NetworkImage(
                          "https://ui-avatars.com/api/?name=${Uri.encodeComponent(currentUser?.name ?? 'User')}&background=D4AF37&color=fff",
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _loading
                            ? const SizedBox(
                          height: 12,
                          width: 80,
                          child: LinearProgressIndicator(
                              color: AppColors.gold),
                        )
                            : Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              _capitalized(
                                  currentUser?.name ?? ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PlayfairDisplay',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentUser?.email ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white24, size: 14),
                    ],
                  ),
                ),
              ),

              // Student badge
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.3)),
                ),
                child: const Text(
                  "STUDENT",
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),

              Divider(color: Colors.white.withOpacity(0.08)),

              // ── Menu Items ───────────────────────────
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerItem(
                      Icons.home_outlined,
                      "Home",
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      Icons.menu_book_outlined,
                      "My Courses",
                      onTap: () {
                        Navigator.pop(context);
                        // My Learning tab is index 2
                      },
                    ),
                    _drawerItem(
                      Icons.live_tv_outlined,
                      "Live Classes",
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      Icons.workspace_premium_outlined,
                      "Certificates",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const CertificatesScreen()),
                        );
                      },
                    ),
                    _drawerItem(
                      Icons.card_giftcard_outlined,
                      "Refer & Earn",
                      onTap: () => Navigator.pop(context),
                    ),

                    Divider(
                        color: Colors.white.withOpacity(0.08),
                        height: 24),

                    _drawerItem(
                      Icons.person_outline,
                      "Profile",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const ProfileScreen()),
                        );
                      },
                    ),
                    _drawerItem(
                      Icons.settings_outlined,
                      "Settings",
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerItem(
                      Icons.help_outline,
                      "Help & Support",
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withOpacity(0.08)),

              // ── Logout ───────────────────────────────
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout,
                      color: Colors.red, size: 18),
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title,
      {required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  String _capitalized(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1405),
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF3A1F1F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              "Logout Confirmation",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Are you sure you want to log out of Arun Mehndi Studio?",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Log Out",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Inter')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Cancel",
                    style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Inter')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}