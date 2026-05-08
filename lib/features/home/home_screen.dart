import 'dart:convert';
import 'package:flutter/material.dart';

import '../../widgets/side_drawer.dart';
import '../../models/user_model.dart';
import '../../core/helpers/storage_helper.dart';

import 'widgets/home_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/offer_banner.dart';
import 'widgets/categories_section.dart';
import 'widgets/featured_courses.dart';
import 'widgets/upcoming_live_class.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSeeAllCourses; // ✅ callback for "See All"

  const HomeScreen({super.key, this.onSeeAllCourses});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    String? userJson = await StorageHelper.getUser();
    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      if (mounted) {
        setState(() {
          currentUser = UserModel.fromJson(userMap);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                )
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.notifications_none, color: Colors.black87),
            ),
          )
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              // White top section
              Container(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      HomeHeader(user: currentUser!),
                      const SizedBox(height: 10),
                      const SearchBarWidget(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              const OfferBanner(),

              // ✅ Categories with onSeeAll callback
              CategoriesSection(
                onSeeAll: widget.onSeeAllCourses,
              ),

              // ✅ Featured courses from API with onSeeAll callback
              FeaturedCourses(
                onSeeAll: widget.onSeeAllCourses,
              ),

              const UpcomingLiveClass(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}