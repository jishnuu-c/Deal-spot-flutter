import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final int id;
  final int userId;
  final String? userFullName;
  final String? userEmail;
  final String type; // 'FLASH_DEAL' | 'PRICE_DROP' | 'OFFER_EXPIRY' | 'NEW_FLYER' | 'COUPON_ALERT' | 'PRODUCT_ALERT' | 'SYSTEM'
  final String channel; // 'PUSH' | 'EMAIL' | 'SMS' | 'IN_APP'
  final String titleEn;
  final String titleAr;
  final String? bodyEn;
  final String? bodyAr;
  final int? refId;
  final String? refType; // 'OFFER' | 'FLYER' | 'PRODUCT' | 'COUPON' | 'SYSTEM'
  final String? deepLink;
  final int isRead;
  final String sentAt;
  final String? createdAt;

  const Notification({
    required this.id,
    required this.userId,
    this.userFullName,
    this.userEmail,
    required this.type,
    required this.channel,
    required this.titleEn,
    required this.titleAr,
    this.bodyEn,
    this.bodyAr,
    this.refId,
    this.refType,
    this.deepLink,
    required this.isRead,
    required this.sentAt,
    this.createdAt,
  });

  bool get read => isRead == 1;

  Notification copyWith({
    int? id,
    int? userId,
    String? userFullName,
    String? userEmail,
    String? type,
    String? channel,
    String? titleEn,
    String? titleAr,
    String? bodyEn,
    String? bodyAr,
    int? refId,
    String? refType,
    String? deepLink,
    int? isRead,
    String? sentAt,
    String? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      bodyEn: bodyEn ?? this.bodyEn,
      bodyAr: bodyAr ?? this.bodyAr,
      refId: refId ?? this.refId,
      refType: refType ?? this.refType,
      deepLink: deepLink ?? this.deepLink,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
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

  factory Notification.fromJson(Map<String, dynamic> json) {
    int parsedIsRead = 0;
    if (json['read'] is bool) {
      parsedIsRead = (json['read'] as bool) ? 1 : 0;
    } else if (json['is_read'] != null) {
      parsedIsRead = (json['is_read'] is num)
          ? (json['is_read'] as num).toInt()
          : (int.tryParse(json['is_read'].toString()) ?? 0);
    } else if (json['isRead'] != null) {
      parsedIsRead = (json['isRead'] is num)
          ? (json['isRead'] as num).toInt()
          : (int.tryParse(json['isRead'].toString()) ?? 0);
    }

    int parsedId = 0;
    if (json['id'] is num) {
      parsedId = (json['id'] as num).toInt();
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    int parsedUserId = 0;
    if (json['userId'] is num) {
      parsedUserId = (json['userId'] as num).toInt();
    } else if (json['user_id'] is num) {
      parsedUserId = (json['user_id'] as num).toInt();
    } else if (json['userId'] != null) {
      parsedUserId = int.tryParse(json['userId'].toString()) ?? 0;
    } else if (json['user_id'] != null) {
      parsedUserId = int.tryParse(json['user_id'].toString()) ?? 0;
    }

    int? parsedRefId;
    if (json['refId'] is num) {
      parsedRefId = (json['refId'] as num).toInt();
    } else if (json['ref_id'] is num) {
      parsedRefId = (json['ref_id'] as num).toInt();
    } else if (json['refId'] != null) {
      parsedRefId = int.tryParse(json['refId'].toString());
    } else if (json['ref_id'] != null) {
      parsedRefId = int.tryParse(json['ref_id'].toString());
    }

    final sentAtStr = _parseDate(json['sentAt'] ?? json['sent_at']) ??
        DateTime.now().toIso8601String();

    return Notification(
      id: parsedId,
      userId: parsedUserId,
      userFullName: json['userFullName']?.toString() ?? json['user_full_name']?.toString(),
      userEmail: json['userEmail']?.toString() ?? json['user_email']?.toString(),
      type: json['type']?.toString() ?? 'SYSTEM',
      channel: json['channel']?.toString() ?? 'PUSH',
      titleEn: json['titleEn']?.toString() ?? json['title_en']?.toString() ?? '',
      titleAr: json['titleAr']?.toString() ?? json['title_ar']?.toString() ?? '',
      bodyEn: json['bodyEn']?.toString() ?? json['body_en']?.toString(),
      bodyAr: json['bodyAr']?.toString() ?? json['body_ar']?.toString(),
      refId: parsedRefId,
      refType: json['refType']?.toString() ?? json['ref_type']?.toString(),
      deepLink: json['deepLink']?.toString() ?? json['deep_link']?.toString(),
      isRead: parsedIsRead,
      sentAt: sentAtStr,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user_id': userId,
      'userFullName': userFullName,
      'userEmail': userEmail,
      'type': type,
      'channel': channel,
      'titleEn': titleEn,
      'title_en': titleEn,
      'titleAr': titleAr,
      'title_ar': titleAr,
      'bodyEn': bodyEn,
      'body_en': bodyEn,
      'bodyAr': bodyAr,
      'body_ar': bodyAr,
      'refId': refId,
      'ref_id': refId,
      'refType': refType,
      'ref_type': refType,
      'deepLink': deepLink,
      'deep_link': deepLink,
      'isRead': isRead,
      'is_read': isRead,
      'read': isRead == 1,
      'sentAt': sentAt,
      'sent_at': sentAt,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userFullName,
        userEmail,
        type,
        channel,
        titleEn,
        titleAr,
        bodyEn,
        bodyAr,
        refId,
        refType,
        deepLink,
        isRead,
        sentAt,
        createdAt,
      ];
}

class BroadcastNotificationPayload {
  final String titleEn;
  final String titleAr;
  final String? bodyEn;
  final String? bodyAr;
  final String type;
  final String channel;
  final int? refId;
  final String? refType;
  final String? deepLink;
  final int? targetUserId;

  const BroadcastNotificationPayload({
    required this.titleEn,
    required this.titleAr,
    this.bodyEn,
    this.bodyAr,
    this.type = 'FLASH_DEAL',
    this.channel = 'PUSH',
    this.refId,
    this.refType,
    this.deepLink,
    this.targetUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'titleEn': titleEn,
      'titleAr': titleAr,
      'bodyEn': bodyEn,
      'bodyAr': bodyAr,
      'type': type,
      'channel': channel,
      'refId': refId,
      'refType': refType,
      'deepLink': deepLink,
      'targetUserId': targetUserId,
    };
  }
}
