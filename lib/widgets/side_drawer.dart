import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mehndi_student_app/core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/helpers/storage_helper.dart';
import '../models/user_model.dart';
import '../features/auth/login_screen.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({super.key});

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {

  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {

    String? userJson = await StorageHelper.getUser();

    if(userJson != null){

      Map<String,dynamic> userMap = jsonDecode(userJson);

      setState(() {
        currentUser = UserModel.fromJson(userMap);
      });

    }

  }

  Future<void> logout() async {

    /// remove token + user
    await StorageHelper.logout();

    if(!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
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

              const SizedBox(height: 20),

              CircleAvatar(
                radius: 30,
                backgroundImage: currentUser?.profileImage != null
                    ? NetworkImage(currentUser!.profileImage!)
                    : NetworkImage(
                  "https://ui-avatars.com/api/?name=${currentUser?.name ?? "User"}",
                ),
              ),

              const SizedBox(height: 10),

              Text(
                (() {
                  String text = currentUser?.name ?? "Loading...";
                  if (text.isEmpty) return text;
                  return text[0].toUpperCase() + text.substring(1);
                })(),
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.primary,
                ),
              ),


              const Text(
                "STUDENT",
                  style: AppTextStyles.body

              ),

              const Divider(color: Colors.white24),

              drawerItem(Icons.home, "Home"),
              drawerItem(Icons.menu_book, "My Courses"),
              drawerItem(Icons.live_tv, "Live Classes"),
              drawerItem(Icons.school, "Certificates"),
              drawerItem(Icons.card_giftcard, "Refer & Earn"),

              const Divider(color: Colors.white24),

              drawerItem(Icons.settings, "Settings"),

              ListTile(
                leading: const Icon(Icons.logout,color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  showLogoutDialog(context);
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget drawerItem(IconData icon,String title){

    return ListTile(
      leading: Icon(icon,color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {},
    );
  }

}




void showLogoutDialog(BuildContext context) {

  showModalBottomSheet(

    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,

    builder: (context){

      return Container(

        padding: const EdgeInsets.all(24),

        decoration: const BoxDecoration(

          color: Color(0xFF1A1405),

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),

        ),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            /// ICON
            Container(

              width: 60,
              height: 60,

              decoration: const BoxDecoration(
                color: Color(0xFF3A1F1F),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 28,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Logout Confirmation",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Are you sure you want to log out of Arun Mehndi Studio? You will need to sign in again to access your courses.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 24),

            /// LOGOUT BUTTON
            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                onPressed: () async {

                  await StorageHelper.logout();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                        (route) => false,
                  );

                },

                child: const Text(
                  "Log Out",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// CANCEL BUTTON
            SizedBox(

              width: double.infinity,

              child: OutlinedButton(

                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                onPressed: (){
                  Navigator.pop(context);
                },

                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          ],
        ),
      );
    },
  );
}