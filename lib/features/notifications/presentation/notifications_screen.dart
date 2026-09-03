import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_repository.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart' as model;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    if (!authState.isLoggedIn) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: Text(tr.get('notifications'))),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Please sign in to view your notifications.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                  onPressed: () => context.go('/login'),
                  child: Text(tr.get('login')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userId = authState.currentUser!.id;
    final list = ref.watch(notificationRepositoryProvider.notifier).getNotificationsForUser(userId);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.get('notifications'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            if (list.any((n) => n.isRead == 0))
              TextButton(
                onPressed: () {
                  ref.read(notificationRepositoryProvider.notifier).markAllAsRead(userId);
                },
                child: Text(tr.get('mark_all_read'), style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(tr.get('no_notifications'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notif = list[index];
                  final isUnread = notif.isRead == 0;
                  final title = isRtl ? notif.titleAr : notif.titleEn;
                  final date = notif.sentAt.split('T')[0];

                  return Container(
                    decoration: BoxDecoration(
                      color: isUnread
                          ? (isDark ? const Color(0xFF163E27).withOpacity(0.5) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnread
                            ? const Color(0xFF16A34A).withOpacity(0.4)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isUnread ? const Color(0xFF16A34A) : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        radius: 20,
                        child: Icon(_getIconForType(notif.type), size: 20),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      onTap: () {
                        ref.read(notificationRepositoryProvider.notifier).markAsRead(notif.id);
                        if (notif.deepLink != null && notif.deepLink!.isNotEmpty) {
                          context.go(notif.deepLink!);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'offer':
        return Icons.local_offer;
      case 'flyer':
        return Icons.menu_book;
      case 'coupon':
        return Icons.confirmation_number;
      default:
        return Icons.notifications;
    }
  }
}
