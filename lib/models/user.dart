import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String username;
  final String password;
  final List<Map<String, dynamic>> performanceHistory;

  User({
    required this.username,
    required this.password,
    this.performanceHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'performanceHistory': performanceHistory,
      'timestamp': Timestamp.now(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      password: map['password'],
      performanceHistory:
          List<Map<String, dynamic>>.from(map['performanceHistory'] ?? []),
    );
  }
}
