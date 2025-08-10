import 'package:cloud_firestore/cloud_firestore.dart';

enum ActionType {
  login,
  logout,
  quizCreate,
  quizStart,
  quizEnd,
  attendanceMark,
  feedbackSubmit,
  userCreate,
  userUpdate,
  // ... other actions
}

class AuditLog {
  final String id;
  final String userId;
  final ActionType action;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.details,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userId: json['user_id'],
      action: ActionType.values.byName(json['action']),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'action': action.name,
        'timestamp': timestamp,
        'details': details,
      };
} 