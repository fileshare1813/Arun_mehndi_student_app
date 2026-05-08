import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key, VoidCallback? onSeeAll});

  Future<List<CategoryModel>> fetchCategories() async {
    const String url =
        "https://api.aktuhub.in/api/categories.php";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      List data = jsonData["data"];

      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                "Failed to load categories",
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final categories = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "See All",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding:
                      const EdgeInsets.only(
                        right: 20,
                      ),
                      child: CategoryItem(
                        category: category,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoryItem extends StatelessWidget {
  final CategoryModel category;

  const CategoryItem({
    super.key,
    required this.category,
  });

  String getEmoji(String name) {
    switch (name.toLowerCase()) {
      case "mehndi":
        return "🖌️";
      case "nail art":
        return "💅";
      case "makeup":
        return "💄";
      case "beauty":
        return "✨";
      default:
        return "📚";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor:
          Colors.pink.shade50,
          child: Text(
            getEmoji(category.name),
            style: const TextStyle(
              fontSize: 26,
            ),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: 70,
          child: Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.description,
  });

  factory CategoryModel.fromJson(
      Map<String, dynamic> json) {
    return CategoryModel(
      id: json["id"].toString(),
      name: json["name"] ?? "",
      icon: json["icon"],
      description: json["description"] ?? "",
    );
  }
}