import 'package:flutter/material.dart';
import 'package:mehndi_student_app/core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/user_model.dart';

class HomeHeader extends StatelessWidget {

  final UserModel user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {

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
                ),
              ),

              const SizedBox(height: 4),
              Text(
                user.name.isNotEmpty
                    ? '${user.name[0].toUpperCase()}${user.name.substring(1)}'
                    : user.name,
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.primary,
                ),
              ),

            ],
          ),

          CircleAvatar(

            radius: 24,

            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : NetworkImage(
                "https://ui-avatars.com/api/?name=${user.name}&background=random"
            ),
          )

        ],
      ),
    );
  }
}