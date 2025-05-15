class Trip {
  final int id;
  final int? userId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String destination;
  final int personCount;
  final int braveLevel;
  final int missionFrequency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalMissions;
  final int completedMissions;

  Trip({
    required this.id,
    this.userId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.destination,
    required this.personCount,
    required this.braveLevel,
    required this.missionFrequency,
    this.createdAt,
    this.updatedAt,
    required this.totalMissions,
    required this.completedMissions,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        destination: json['destination'],
        personCount: json['personCount'],
        braveLevel: json['braveLevel'],
        missionFrequency: json['missionFrequency'],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
        totalMissions: json['totalMissions'] ?? 0,
        completedMissions: json['completedMissions'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'destination': destination,
        'personCount': personCount,
        'braveLevel': braveLevel,
        'missionFrequency': missionFrequency,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'totalMissions': totalMissions,
        'completedMissions': completedMissions,
      };
} 