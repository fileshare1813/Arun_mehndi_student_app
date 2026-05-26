import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/helpers/storage_helper.dart';
import '../../../models/user_model.dart';
import '../../profile/profile_screen.dart';

class HomeHeader extends StatefulWidget {
  final UserModel user;
  const HomeHeader({super.key, required this.user});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    ProfileUpdateNotifier.instance.addListener(_onProfileUpdated);
  }

  @override
  void dispose() {
    ProfileUpdateNotifier.instance.removeListener(_onProfileUpdated);
    super.dispose();
  }

  void _onProfileUpdated() {
    final updated = ProfileUpdateNotifier.instance.latest;
    if (updated != null && mounted) {
      setState(() => _user = UserModel.fromJson(updated));
    }
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      setState(() => _user = widget.user);
    }
  }

  String get _avatarUrl {
    if (_user.profileImage != null && _user.profileImage!.isNotEmpty) {
      return "https://api.aktuhub.in/uploads/profile_images/${_user.profileImage}";
    }
    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(_user.name)}&background=D4AF37&color=fff";
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user.name.isNotEmpty
        ? '${_user.name[0].toUpperCase()}${_user.name.substring(1)}'
        : _user.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome,",
                style: AppTextStyles.heading.copyWith(
                  color: Colors.black,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.primary,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          // Avatar — updates in real-time when profile changes
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.45),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  backgroundImage: NetworkImage(_avatarUrl),
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}