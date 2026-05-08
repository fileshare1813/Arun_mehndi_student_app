class Course {
  final int id;
  final String title;
  final String thumbnail;
  final String price;
  final String oldPrice;
  final String level;
  final String category;
  final String description;
  final double rating;
  final int totalReviews;
  final int totalStudents;
  final String instructor;
  final String duration;
  final int totalLessons;

  Course({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.price,
    this.oldPrice = "",
    required this.level,
    required this.category,
    required this.description,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalStudents = 0,
    this.instructor = "",
    this.duration = "",
    this.totalLessons = 0,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? "",
      thumbnail: json['thumbnail'] ?? "",
      price: json['price'].toString(),
      oldPrice: json['old_price']?.toString() ?? "",
      level: json['level'] ?? "",
      category: json['category'] ?? "",
      description: json['description'] ?? "",
      rating: double.tryParse(json['rating']?.toString() ?? "0") ?? 0.0,
      totalReviews: int.tryParse(json['total_reviews']?.toString() ?? "0") ?? 0,
      totalStudents: int.tryParse(json['total_students']?.toString() ?? "0") ?? 0,
      instructor: json['instructor'] ?? "",
      duration: json['duration'] ?? "",
      totalLessons: int.tryParse(json['total_lessons']?.toString() ?? "0") ?? 0,
    );
  }
}