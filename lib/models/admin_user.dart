import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String? passwordHash;
  final String role; // 'admin' | 'superadmin' | 'editor'
  final int isActive;
  final String? lastLoginAt;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.passwordHash,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
  });

  AdminUser copyWith({
    int? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? role,
    int? isActive,
    String? lastLoginAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      passwordHash: json['password_hash'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as int,
      lastLoginAt: json['last_login_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
      'is_active': isActive,
      'last_login_at': lastLoginAt,
    };
  }

  @override
  List<Object?> get props => [id, fullName, email, passwordHash, role, isActive, lastLoginAt];
}
