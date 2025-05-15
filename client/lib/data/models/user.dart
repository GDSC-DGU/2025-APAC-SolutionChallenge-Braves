class User {
  final int id;
  final String socialId;
  final String email;
  final String username;
  final String? profileImage;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.socialId,
    required this.email,
    required this.username,
    this.profileImage,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        socialId: json['social_id'],
        email: json['email'],
        username: json['username'],
        profileImage: json['profile_image'],
        role: json['role'],
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'social_id': socialId,
        'email': email,
        'username': username,
        'profile_image': profileImage,
        'role': role,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
} 