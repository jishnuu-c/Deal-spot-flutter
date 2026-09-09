import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'api_client.dart';

class NotificationState {
  final List<Notification> notifications;
  final int totalCount;
  final int unreadCount;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  const NotificationState({
    required this.notifications,
    this.totalCount = 0,
    this.unreadCount = 0,
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<Notification>? notifications,
    int? totalCount,
    int? unreadCount,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      totalCount: totalCount ?? this.totalCount,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _apiClient;

  static final List<Notification> _initialSeedNotifications = [
    const Notification(
      id: 1,
      userId: 101,
      userFullName: 'Fahad Al-Otaibi',
      userEmail: 'fahad@gmail.com',
      type: 'FLASH_DEAL',
      channel: 'PUSH',
      titleEn: '🔥 Flash 50% Off on Fresh Produce!',
      titleAr: '🔥 خصم 50% على المنتجات الطازجة لفترة محدودة!',
      bodyEn: 'Get 50% off on all fresh fruits and vegetables until midnight!',
      bodyAr: 'احصل على خصم 50% على جميع الخضار والفواكه الطازجة حتى منتصف الليل!',
      refId: 1,
      refType: 'OFFER',
      deepLink: '/offers/1',
      isRead: 0,
      sentAt: '2026-08-25T14:30:00',
    ),
    const Notification(
      id: 2,
      userId: 102,
      userFullName: 'Sarah Ahmed',
      userEmail: 'sarah@dealspot.com',
      type: 'PRICE_DROP',
      channel: 'PUSH',
      titleEn: '📉 Price Drop on Samsung Galaxy S24 Ultra',
      titleAr: '📉 انخفاض في سعر سامسونج جالكسي S24 ألترا',
      bodyEn: 'The price for Samsung Galaxy S24 Ultra dropped to 3,499 SAR!',
      bodyAr: 'انخفض سعر هاتف سامسونج جالكسي S24 ألترا إلى 3,499 ريال!',
      refId: 2,
      refType: 'PRODUCT',
      deepLink: '/products/2',
      isRead: 1,
      sentAt: '2026-08-24T10:15:00',
    ),
    const Notification(
      id: 3,
      userId: 0,
      userFullName: null,
      userEmail: null,
      type: 'NEW_FLYER',
      channel: 'PUSH',
      titleEn: '📰 Lulu Hypermarket Weekly Deals Magazine',
      titleAr: '📰 مجلة عروض لولو هايبرماركت الأسبوعية',
      bodyEn: 'Browse the latest digital catalog and discover huge savings across all branches.',
      bodyAr: 'تصفح أحدث مجلة عروض رقمية واكتشف توفيراً كبيراً في كافة الفروع.',
      refId: 1,
      refType: 'FLYER',
      deepLink: '/flyers/1',
      isRead: 1,
      sentAt: '2026-08-23T18:00:00',
    ),
    const Notification(
      id: 4,
      userId: 103,
      userFullName: 'Mohammed Ali',
      userEmail: 'mali@gmail.com',
      type: 'COUPON_ALERT',
      channel: 'EMAIL',
      titleEn: '🎟️ Extra 20% Off Coupon Code: SAVE20',
      titleAr: '🎟️ كود خصم إضافي 20%: SAVE20',
      bodyEn: 'Apply code SAVE20 during checkout for an instant discount on your cart.',
      bodyAr: 'استخدم الكود SAVE20 عند الدفع للحصول على خصم فوري على سلتك.',
      refId: 1,
      refType: 'COUPON',
      deepLink: '/coupons',
      isRead: 0,
      sentAt: '2026-08-22T12:00:00',
    ),
    const Notification(
      id: 5,
      userId: 0,
      userFullName: null,
      userEmail: null,
      type: 'SYSTEM',
      channel: 'PUSH',
      titleEn: '🎉 Welcome to DealSpot Saudi Arabia',
      titleAr: '🎉 أهلاً بك في تطبيق ديل سبوت المملكة العربية السعودية',
      bodyEn: 'Discover exclusive offers, weekly flyers, and discounts in your city.',
      bodyAr: 'اكتشف العروض الحصرية والمجلات الأسبوعية والخصومات في مدينتك.',
      refId: null,
      refType: 'SYSTEM',
      deepLink: null,
      isRead: 1,
      sentAt: '2026-08-20T09:00:00',
    ),
  ];

  NotificationNotifier(this._apiClient)
      : super(NotificationState(
          notifications: _initialSeedNotifications,
          totalCount: _initialSeedNotifications.length,
          unreadCount: _initialSeedNotifications.where((n) => n.isRead == 0).length,
        ));

  int getUnreadCount([int? userId]) {
    if (userId != null) {
      return state.notifications.where((n) => (n.userId == userId || n.userId == 0) && n.isRead == 0).length;
    }
    return state.unreadCount;
  }

  List<Notification> getNotificationsForUser(int userId) {
    return state.notifications.where((n) => n.userId == userId || n.userId == 0).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  Future<void> fetchAllNotifications({
    int page = 0,
    int size = 15,
    String? search,
    String? type,
    String? channel,
    bool? isRead,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (channel != null && channel.isNotEmpty) queryParams['channel'] = channel;
      if (isRead != null) queryParams['isRead'] = isRead;

      final response = await _apiClient.get(
        '/notifications/all',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is String) {
          raw = jsonDecode(raw);
        }
        List rawList = [];
        int totalElements = 0;
        if (raw is List) {
          rawList = raw;
          totalElements = raw.length;
        } else if (raw is Map && raw['content'] is List) {
          rawList = raw['content'] as List;
          totalElements = (raw['totalElements'] as num?)?.toInt() ?? rawList.length;
        } else if (raw is Map && raw['data'] is List) {
          rawList = raw['data'] as List;
          totalElements = (raw['total'] as num?)?.toInt() ?? rawList.length;
        }

        final list = <Notification>[];
        for (final item in rawList) {
          try {
            if (item is Map<String, dynamic>) {
              list.add(Notification.fromJson(item));
            } else if (item is Map) {
              list.add(Notification.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (_) {}
        }

        if (list.isNotEmpty) {
          state = state.copyWith(
            notifications: list,
            totalCount: totalElements,
            unreadCount: list.where((n) => n.isRead == 0).length,
            isLoading: false,
          );
          return;
        }
      }
    } catch (_) {
      // Graceful fallback to client-side filtered seed list
    }

    // Client-side fallback filter
    var filtered = List<Notification>.from(state.notifications.isEmpty ? _initialSeedNotifications : state.notifications);
    if (type != null && type.isNotEmpty && type != 'ALL') {
      filtered = filtered.where((n) => n.type.toUpperCase() == type.toUpperCase()).toList();
    }
    if (channel != null && channel.isNotEmpty && channel != 'ALL') {
      filtered = filtered.where((n) => n.channel.toUpperCase() == channel.toUpperCase()).toList();
    }
    if (isRead != null) {
      filtered = filtered.where((n) => (n.isRead == 1) == isRead).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      filtered = filtered.where((n) {
        return n.titleEn.toLowerCase().contains(q) ||
            n.titleAr.toLowerCase().contains(q) ||
            (n.userFullName?.toLowerCase().contains(q) ?? false) ||
            (n.userEmail?.toLowerCase().contains(q) ?? false) ||
            (n.bodyEn?.toLowerCase().contains(q) ?? false) ||
            (n.bodyAr?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    state = state.copyWith(
      notifications: filtered,
      totalCount: filtered.length,
      unreadCount: filtered.where((n) => n.isRead == 0).length,
      isLoading: false,
    );
  }

  Future<void> fetchMyNotifications({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.get(
        '/notifications/my',
        queryParameters: {'page': page, 'size': size},
      );
      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is String) raw = jsonDecode(raw);
        List rawList = [];
        if (raw is List) {
          rawList = raw;
        } else if (raw is Map && raw['content'] is List) {
          rawList = raw['content'] as List;
        }

        final list = <Notification>[];
        for (final item in rawList) {
          try {
            if (item is Map<String, dynamic>) {
              list.add(Notification.fromJson(item));
            } else if (item is Map) {
              list.add(Notification.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (_) {}
        }
        if (list.isNotEmpty) {
          state = state.copyWith(
            notifications: list,
            unreadCount: list.where((n) => n.isRead == 0).length,
          );
        }
      }
    } catch (_) {}
  }

  Future<Notification> broadcastNotification(BroadcastNotificationPayload payload) async {
    state = state.copyWith(isSending: true);
    try {
      final response = await _apiClient.post(
        '/notifications/broadcast',
        data: payload.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is String) raw = jsonDecode(raw);
        if (raw is Map<String, dynamic>) {
          final created = Notification.fromJson(raw);
          state = state.copyWith(
            notifications: [created, ...state.notifications],
            totalCount: state.totalCount + 1,
            isSending: false,
          );
          return created;
        }
      }
    } catch (_) {}

    // Fallback local broadcast creation
    final newId = state.notifications.isEmpty
        ? 1
        : state.notifications.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
    final created = Notification(
      id: newId,
      userId: payload.targetUserId ?? 0,
      userFullName: payload.targetUserId != null ? 'User #${payload.targetUserId}' : null,
      userEmail: null,
      type: payload.type,
      channel: payload.channel,
      titleEn: payload.titleEn,
      titleAr: payload.titleAr,
      bodyEn: payload.bodyEn,
      bodyAr: payload.bodyAr,
      refId: payload.refId,
      refType: payload.refType,
      deepLink: payload.deepLink,
      isRead: 0,
      sentAt: DateTime.now().toIso8601String(),
    );

    state = state.copyWith(
      notifications: [created, ...state.notifications],
      totalCount: state.totalCount + 1,
      isSending: false,
    );
    return created;
  }

  Future<void> markAsRead(int id) async {
    try {
      await _apiClient.put('/notifications/$id/read');
    } catch (_) {}

    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: 1);
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => n.isRead == 0).length,
    );
  }

  Future<void> markAllAsRead([int? userId]) async {
    try {
      await _apiClient.put('/notifications/read-all');
    } catch (_) {}

    final updated = state.notifications.map((n) {
      if (userId == null || n.userId == userId || n.userId == 0) {
        return n.copyWith(isRead: 1);
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => n.isRead == 0).length,
    );
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _apiClient.delete('/notifications/$id');
    } catch (_) {}

    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(
      notifications: updated,
      totalCount: (state.totalCount - 1).clamp(0, 999999),
      unreadCount: updated.where((n) => n.isRead == 0).length,
    );
  }

  // Backwards compatibility helper for customer dispatch
  void createNotification(
    int userId,
    String titleEn,
    String titleAr,
    String type,
    String channel, {
    int? refId,
    String? refType,
    String? link,
  }) {
    broadcastNotification(BroadcastNotificationPayload(
      titleEn: titleEn,
      titleAr: titleAr,
      type: type,
      channel: channel,
      refId: refId,
      refType: refType,
      deepLink: link,
      targetUserId: userId,
    ));
  }
}

final notificationRepositoryProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationNotifier(apiClient);
});
