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
      id: json['id'] as int,
      cityId: json['city_id'] as int?,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      preferredLang: json['preferred_lang'] as String? ?? 'en',
      fcmToken: json['fcm_token'] as String?,
      apnsToken: json['apns_token'] as String?,
      emailVerified: json['email_verified'] as int? ?? 0,
      phoneVerified: json['phone_verified'] as int? ?? 0,
      isActive: json['is_active'] as int? ?? 1,
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
