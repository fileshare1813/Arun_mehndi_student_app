class UserModel {
  final String name;
  final String email;
  final String? profileImage;
  final String? phone;
  final String? bio;
  final int phoneChangeCount;

  UserModel({
    required this.name,
    required this.email,
    this.profileImage,
    this.phone,
    this.bio,
    this.phoneChangeCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name']?.toString() ?? "",
      email: json['email']?.toString() ?? "",
      profileImage: json['profile_image']?.toString(),
      phone: json['phone']?.toString(),
      bio: json['bio']?.toString(),
      phoneChangeCount:
      int.tryParse(json['phone_change_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "profile_image": profileImage,
      "phone": phone,
      "bio": bio,
      "phone_change_count": phoneChangeCount.toString(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? profileImage,
    String? phone,
    String? bio,
    int? phoneChangeCount,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      phoneChangeCount: phoneChangeCount ?? this.phoneChangeCount,
    );
  }
}