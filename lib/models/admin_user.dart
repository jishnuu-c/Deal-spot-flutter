import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String? passwordHash;
  final String role; // 'SUPER_ADMIN' | 'CONTENT_MANAGER' | 'SUPPORT' | 'ANALYST' | 'STORE_MANAGER' | 'admin'
  final int isActive;
  final String? lastLoginAt;
  final String? createdAt;
  final int? storeId;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.passwordHash,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.storeId,
  });

  bool get active => isActive == 1;

  AdminUser copyWith({
    int? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? role,
    int? isActive,
    String? lastLoginAt,
    String? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
      storeId: storeId ?? this.storeId,
    );
  }

  static String? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) return val;
    if (val is List && val.isNotEmpty) {
      try {
        final year = (val[0] as num).toInt();
        final month = val.length > 1 ? (val[1] as num).toInt() : 1;
        final day = val.length > 2 ? (val[2] as num).toInt() : 1;
        final hour = val.length > 3 ? (val[3] as num).toInt() : 0;
        final min = val.length > 4 ? (val[4] as num).toInt() : 0;
        final sec = val.length > 5 ? (val[5] as num).toInt() : 0;
        return DateTime(year, month, day, hour, min, sec).toIso8601String();
      } catch (_) {
        return val.toString();
      }
    }
    return val.toString();
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    int parsedIsActive = 1;
    if (json['active'] is bool) {
      parsedIsActive = (json['active'] as bool) ? 1 : 0;
    } else if (json['is_active'] != null) {
      parsedIsActive = (json['is_active'] is num)
          ? (json['is_active'] as num).toInt()
          : (int.tryParse(json['is_active'].toString()) ?? 1);
    } else if (json['isActive'] != null) {
      parsedIsActive = (json['isActive'] is num)
          ? (json['isActive'] as num).toInt()
          : (int.tryParse(json['isActive'].toString()) ?? 1);
    }

    int parsedId = 0;
    if (json['id'] is num) {
      parsedId = (json['id'] as num).toInt();
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    String parsedRole = 'SUPER_ADMIN';
    if (json['role'] is String) {
      parsedRole = json['role'] as String;
    } else if (json['role'] is Map && json['role']['name'] != null) {
      parsedRole = json['role']['name'].toString();
    } else if (json['role'] != null) {
      parsedRole = json['role'].toString();
    }

    return AdminUser(
      id: parsedId,
      fullName: json['full_name']?.toString() ??
          json['fullName']?.toString() ??
          json['name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      passwordHash: json['password_hash']?.toString() ??
          json['passwordHash']?.toString(),
      role: parsedRole,
      isActive: parsedIsActive,
      lastLoginAt: _parseDate(json['last_login_at'] ?? json['lastLoginAt']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      storeId: json['store_id'] != null
          ? (int.tryParse(json['store_id'].toString()))
          : (json['storeId'] != null ? int.tryParse(json['storeId'].toString()) : null),
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
      'active': isActive == 1,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
      'store_id': storeId,
    };
  }

  @override
  List<Object?> get props => [id, fullName, email, passwordHash, role, isActive, lastLoginAt, createdAt, storeId];
}
