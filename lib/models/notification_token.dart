import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationToken {
  final String id;
  final String userId;
  final String token;
  final DateTime createdAt;

  NotificationToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.createdAt,
  });

  factory NotificationToken.fromJson(Map<String, dynamic> json) {
    return NotificationToken(
      id: json['id'],
      userId: json['user_id'],
      token: json['token'],
      createdAt: (json['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'token': token,
        'created_at': createdAt,
      };
} 