class Login{
  int id;
  String name;
  String role;
  String token;
  int? sessionId;

  Login({
    required this.id,
    required this.name,
    required this.role,
    required this.token,
    this.sessionId,
  });

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      token: json['token'],
      sessionId: json['sessionId'],
    );
  }
}