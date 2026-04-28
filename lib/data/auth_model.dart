// lib/data/auth_model.dart
// ─────────────────────────────────────────────────────────────────────────────
// User session model — passed around the app after successful login
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { student, admin }

class UserSession {
  const UserSession({
    required this.role,
    required this.username,
    this.university,
    this.studentId,
    this.adminNode,
  });

  final UserRole role;

  /// Display name (student ID or node name)
  final String username;

  /// Student only
  final String? university;
  final String? studentId;

  /// Admin only
  final String? adminNode;

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final role = json['role'] == 'admin' ? UserRole.admin : UserRole.student;
    return UserSession(
      role: role,
      username: role == UserRole.admin
          ? (json['node'] ?? '')
          : (json['student_id'] ?? ''),
      university: json['university'],
      studentId: json['student_id'],
      adminNode: json['node'],
    );
  }
}
