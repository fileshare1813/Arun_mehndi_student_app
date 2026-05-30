import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/api/api_endpoints.dart';

class CategoriesSection extends StatelessWidget {
  final VoidCallback? onSeeAll;
  final ValueChanged<String>? onCategoryTap;

  const CategoriesSection({
    super.key,
    this.onSeeAll,
    this.onCategoryTap,
  });

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await http
          .get(
        Uri.parse("${ApiEndpoints.baseUrl}/categories"),
        headers: {"Accept": "application/json"},
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final List<dynamic> data;
        if (jsonData is Map && jsonData['data'] is List) {
          data = jsonData['data'] as List;
        } else if (jsonData is List) {
          data = jsonData;
        } else {
          return [];
        }

        return data
            .map((e) {
          try {
            return CategoryModel.fromJson(
                e as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
            .whereType<CategoryModel>()
            .toList();
      } else {
        throw Exception(
            "Failed to load categories: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Categories fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categories =
        (snapshot.hasError || (snapshot.data?.isEmpty ?? true))
            ? _fallbackCategories()
            : snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Categories",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: onSeeAll,
                    child: const Text(
                      "See All",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w500),
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
                      padding: const EdgeInsets.only(right: 20),
                      child: CategoryItem(
                        category: category,
                        onTap: onCategoryTap != null
                            ? () => onCategoryTap!(category.name)
                            : null,
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

  List<CategoryModel> _fallbackCategories() {
    return [
      CategoryModel(id: "1", name: "Mehndi", description: ""),
      CategoryModel(id: "2", name: "Beauty", description: ""),
      CategoryModel(id: "3", name: "Makeup", description: ""),
      CategoryModel(id: "4", name: "Nail Art", description: ""),
    ];
  }
}

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;

  const CategoryItem({super.key, required this.category, this.onTap});

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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pink.shade50,
            child: Text(getEmoji(category.name),
                style: const TextStyle(fontSize: 26)),
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
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String description;

  CategoryModel(
      {required this.id,
        required this.name,
        this.icon,
        required this.description});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json["id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      icon: json["icon"]?.toString(),
      description: json["description"]?.toString() ?? "",
    );
  }
}