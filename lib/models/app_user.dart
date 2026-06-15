// ============================================================
// models/app_user.dart
// Represents a user stored in Firestore 'users' collection
// ============================================================

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool emailVerified;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.emailVerified,
  });

  // Convert Firestore document → AppUser object
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Admin',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      emailVerified: map['emailVerified'] ?? false,
    );
  }

  // Convert AppUser object → Firestore document
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'emailVerified': emailVerified,
    };
  }
}
