import 'package:equatable/equatable.dart';

class UserDevice extends Equatable {
  final int id;
  final int userId;
  final String platform; // 'ios' | 'android' | 'web'
  final String deviceToken;
  final String? deviceModel;
  final String? appVersion;
  final String? locale;
  final int isActive;

  const UserDevice({
    required this.id,
    required this.userId,
    required this.platform,
    required this.deviceToken,
    this.deviceModel,
    this.appVersion,
    this.locale,
    required this.isActive,
  });

  UserDevice copyWith({
    int? id,
    int? userId,
    String? platform,
    String? deviceToken,
    String? deviceModel,
    String? appVersion,
    String? locale,
    int? isActive,
  }) {
    return UserDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      deviceToken: deviceToken ?? this.deviceToken,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      locale: locale ?? this.locale,
      isActive: isActive ?? this.isActive,
    );
  }

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      platform: json['platform'] as String,
      deviceToken: json['device_token'] as String,
      deviceModel: json['device_model'] as String?,
      appVersion: json['app_version'] as String?,
      locale: json['locale'] as String?,
      isActive: json['is_active'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'platform': platform,
      'device_token': deviceToken,
      'device_model': deviceModel,
      'app_version': appVersion,
      'locale': locale,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, userId, platform, deviceToken, deviceModel, appVersion, locale, isActive];
}
