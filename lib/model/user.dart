class Student {
  final int id;
  String username;
  String password;
  String name;
  final String role;
  String? studentId;
  int? points;
  int? elo;
  String? eloTitle;
  int? totalCourses;
  int? badges;
  String? instructorId;
  int? instructorCourses;
  String? image;
  final DateTime createdAt;
  final DateTime updatedAt;


  Student ({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.studentId,
    this.points,
    this.elo,
    this.eloTitle,
    this.totalCourses,
    this.badges,
    this.instructorId,
    this.instructorCourses,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      name: json['name'],
      role: json['role'],
      studentId: json['studentId'],
      points: json['points'],
      elo: json['elo'],
      eloTitle: json['eloTitle'],
      totalCourses: json['totalCourses'],
      badges: json['badges'],
      instructorId: json['instructorId'],
      instructorCourses: json['instructorCourses'],
      image: json['image'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}