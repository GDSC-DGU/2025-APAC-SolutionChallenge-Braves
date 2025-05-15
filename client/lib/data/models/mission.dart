class Mission {
  final int id;
  final int travelId;
  final String title;
  final String content;
  final String? completionImage;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Mission({
    required this.id,
    required this.travelId,
    required this.title,
    required this.content,
    required this.isCompleted,
    this.completionImage,
    this.createdAt,
    this.updatedAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'],
        travelId: json['travelId'],
        title: json['title'],
        content: json['content'],
        isCompleted: json['isCompleted'] == 1,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
        completionImage: json['completionImage'] != null ? json['completionImage'] : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'travelId': travelId,
        'title': title,
        'content': content,
        'isCompleted': isCompleted ? 1 : 0,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'completionImage': completionImage,
      };
} 