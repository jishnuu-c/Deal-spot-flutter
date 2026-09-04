import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String? passwordHash;
  final String role; // 'admin' | 'superadmin' | 'editor' | 'STORE_MANAGER'
  final int isActive;
  final String? lastLoginAt;
  final int? storeId;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.passwordHash,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    this.storeId,
  });

  AdminUser copyWith({
    int? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? role,
    int? isActive,
    String? lastLoginAt,
    int? storeId,
  }) {
    return AdminUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      storeId: storeId ?? this.storeId,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordHash: json['password_hash'] as String? ?? json['passwordHash'] as String?,
      role: json['role'] as String? ?? 'admin',
      isActive: (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1,
      lastLoginAt: json['last_login_at'] as String? ?? json['lastLoginAt'] as String?,
      storeId: (json['store_id'] as num?)?.toInt() ?? (json['storeId'] as num?)?.toInt(),
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
      'store_id': storeId,
    };
  }

  @override
  List<Object?> get props => [id, fullName, email, passwordHash, role, isActive, lastLoginAt, storeId];
}
