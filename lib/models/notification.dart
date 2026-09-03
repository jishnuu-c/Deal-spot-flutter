import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final int id;
  final int userId;
  final String type; // 'offer' | 'flyer' | 'system' | 'coupon' | string
  final String channel; // 'push' | 'email' | 'in_app' | string
  final String titleEn;
  final String titleAr;
  final int? refId;
  final String? refType;
  final String? deepLink;
  final int isRead;
  final String sentAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.channel,
    required this.titleEn,
    required this.titleAr,
    this.refId,
    this.refType,
    this.deepLink,
    required this.isRead,
    required this.sentAt,
  });

  Notification copyWith({
    int? id,
    int? userId,
    String? type,
    String? channel,
    String? titleEn,
    String? titleAr,
    int? refId,
    String? refType,
    String? deepLink,
    int? isRead,
    String? sentAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      refId: refId ?? this.refId,
      refType: refType ?? this.refType,
      deepLink: deepLink ?? this.deepLink,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String,
      channel: json['channel'] as String,
      titleEn: json['title_en'] as String,
      titleAr: json['title_ar'] as String,
      refId: json['ref_id'] as int?,
      refType: json['ref_type'] as String?,
      deepLink: json['deep_link'] as String?,
      isRead: json['is_read'] as int? ?? 0,
      sentAt: json['sent_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'channel': channel,
      'title_en': titleEn,
      'title_ar': titleAr,
      'ref_id': refId,
      'ref_type': refType,
      'deep_link': deepLink,
      'is_read': isRead,
      'sent_at': sentAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        channel,
        titleEn,
        titleAr,
        refId,
        refType,
        deepLink,
        isRead,
        sentAt,
      ];
}
