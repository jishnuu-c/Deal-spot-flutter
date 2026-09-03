import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';

class NotificationNotifier extends StateNotifier<List<Notification>> {
  NotificationNotifier() : super(const []);

  int getUnreadCount(int userId) {
    return state.where((n) => n.userId == userId && n.isRead == 0).length;
  }

  List<Notification> getNotificationsForUser(int userId) {
    return state.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  void markAsRead(int id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: 1);
      }
      return n;
    }).toList();
  }

  void markAllAsRead(int userId) {
    state = state.map((n) {
      if (n.userId == userId) {
        return n.copyWith(isRead: 1);
      }
      return n;
    }).toList();
  }

  // Admin / System trigger
  void createNotification(int userId, String titleEn, String titleAr, String type, String channel, {int? refId, String? refType, String? link}) {
    final newId = state.isEmpty ? 1 : state.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
    final newNotif = Notification(
      id: newId,
      userId: userId,
      type: type,
      channel: channel,
      titleEn: titleEn,
      titleAr: titleAr,
      refId: refId,
      refType: refType,
      deepLink: link,
      isRead: 0,
      sentAt: DateTime.now().toIso8601String(),
    );
    state = [newNotif, ...state];
  }

  void deleteNotification(int id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationRepositoryProvider = StateNotifierProvider<NotificationNotifier, List<Notification>>((ref) {
  return NotificationNotifier();
});
