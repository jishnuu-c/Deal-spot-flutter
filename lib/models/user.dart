import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final int? cityId;
  final String fullName;
  final String email;
  final String? phone;
  final String preferredLang; // 'en' | 'ar'
  final String? fcmToken;
  final String? apnsToken;
  final int emailVerified;
  final int phoneVerified;
  final int isActive;

  const User({
    required this.id,
    this.cityId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.preferredLang,
    this.fcmToken,
    this.apnsToken,
    required this.emailVerified,
    required this.phoneVerified,
    required this.isActive,
  });

  User copyWith({
    int? id,
    int? cityId,
    String? fullName,
    String? email,
    String? phone,
    String? preferredLang,
    String? fcmToken,
    String? apnsToken,
    int? emailVerified,
    int? phoneVerified,
    int? isActive,
  }) {
    return User(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      preferredLang: preferredLang ?? this.preferredLang,
      fcmToken: fcmToken ?? this.fcmToken,
      apnsToken: apnsToken ?? this.apnsToken,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cityId: (json['cityId'] as num?)?.toInt() ?? (json['city_id'] as num?)?.toInt(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone'] as String?,
      preferredLang: json['preferredLang'] as String? ?? json['preferred_lang'] as String? ?? 'en',
      fcmToken: json['fcmToken'] as String? ?? json['fcm_token'] as String?,
      apnsToken: json['apnsToken'] as String? ?? json['apns_token'] as String?,
      emailVerified: json['emailVerified'] is bool
          ? ((json['emailVerified'] as bool) ? 1 : 0)
          : (json['emailVerified'] as num?)?.toInt() ?? (json['email_verified'] as num?)?.toInt() ?? 0,
      phoneVerified: json['phoneVerified'] is bool
          ? ((json['phoneVerified'] as bool) ? 1 : 0)
          : (json['phoneVerified'] as num?)?.toInt() ?? (json['phone_verified'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] is bool
          ? ((json['isActive'] as bool) ? 1 : 0)
          : (json['isActive'] as num?)?.toInt() ?? (json['is_active'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_id': cityId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'preferred_lang': preferredLang,
      'fcm_token': fcmToken,
      'apns_token': apnsToken,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        cityId,
        fullName,
        email,
        phone,
        preferredLang,
        fcmToken,
        apnsToken,
        emailVerified,
        phoneVerified,
        isActive,
      ];
}
