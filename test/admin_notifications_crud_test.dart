import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealspot_flutter/core/services/notification_repository.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/notifications_crud_screen.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockNotificationNotifier extends StateNotifier<NotificationState>
    implements NotificationNotifier {
  MockNotificationNotifier(List<Notification> notifs)
      : super(NotificationState(
          notifications: notifs,
          totalCount: notifs.length,
          unreadCount: notifs.where((n) => n.isRead == 0).length,
          isLoading: false,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> fetchAllNotifications({
    int page = 0,
    int size = 15,
    String? search,
    String? type,
    String? channel,
    bool? isRead,
  }) async {}

  @override
  Future<Notification> broadcastNotification(BroadcastNotificationPayload payload) async {
    final newId = state.notifications.length + 1;
    final created = Notification(
      id: newId,
      userId: payload.targetUserId ?? 0,
      userFullName: payload.targetUserId != null ? 'User #${payload.targetUserId}' : null,
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
      sentAt: '2026-09-01T12:00:00',
    );
    state = state.copyWith(
      notifications: [created, ...state.notifications],
      totalCount: state.totalCount + 1,
    );
    return created;
  }

  @override
  Future<void> deleteNotification(int id) async {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(
      notifications: updated,
      totalCount: updated.length,
      unreadCount: updated.where((n) => n.isRead == 0).length,
    );
  }
}

void main() {
  const notif1 = Notification(
    id: 1,
    userId: 101,
    userFullName: 'Fahad Al-Otaibi',
    userEmail: 'fahad@dealspot.com',
    type: 'FLASH_DEAL',
    channel: 'PUSH',
    titleEn: 'Flash 50% Off Deal',
    titleAr: 'عرض خاص خصم 50%',
    bodyEn: 'Enjoy half price on all electronics today.',
    bodyAr: 'استمتع بنصف السعر على كافة الإلكترونيات اليوم.',
    refId: 1,
    refType: 'OFFER',
    deepLink: '/offers/1',
    isRead: 0,
    sentAt: '2026-08-25T14:30:00',
  );

  const notif2 = Notification(
    id: 2,
    userId: 0,
    userFullName: null,
    userEmail: null,
    type: 'NEW_FLYER',
    channel: 'PUSH',
    titleEn: 'Lulu Weekly Flyer',
    titleAr: 'مجلة عروض لولو الأسبوعية',
    bodyEn: 'Browse latest savings.',
    bodyAr: 'تصفح أحدث التخفيضات.',
    refId: 2,
    refType: 'FLYER',
    deepLink: '/flyers/2',
    isRead: 1,
    sentAt: '2026-08-24T10:00:00',
  );

  testWidgets('NotificationsCrudScreen renders header, stats, and notification cards', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([notif1, notif2]),
          ),
        ],
        child: const MaterialApp(
          home: NotificationsCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Notification Delivery & Broadcast'), findsOneWidget);
    expect(find.text('Compose & Broadcast Notification'), findsOneWidget);

    // Verify Stats Grid
    expect(find.text('Delivered Alerts'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // 2 delivered alerts
    expect(find.text('Linkable Active Offers'), findsOneWidget);
    expect(find.text('Linkable Active Flyers'), findsOneWidget);

    // Verify Cards
    expect(find.text('Flash 50% Off Deal'), findsOneWidget);
    expect(find.text('FLASH DEAL'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.textContaining('Fahad Al-Otaibi'), findsOneWidget);
    expect(find.text('/offers/1'), findsOneWidget);

    expect(find.text('Lulu Weekly Flyer'), findsOneWidget);
    expect(find.text('NEW FLYER'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
  });

  testWidgets('NotificationsCrudScreen opens Compose Broadcast modal and dispatches', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([notif1, notif2]),
          ),
        ],
        child: const MaterialApp(
          home: NotificationsCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Compose & Broadcast Notification
    await tester.tap(find.text('Compose & Broadcast Notification'));
    await tester.pumpAndSettle();

    // Verify Modal Dialog
    expect(find.text('Link Related Deal / Entity'), findsOneWidget);
    expect(find.text('Live Alert Preview'), findsOneWidget);
    expect(find.text('DealSpot'), findsOneWidget);
    expect(find.text('Audience Coverage'), findsOneWidget);

    // Fill Titles
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Flash 50% Off on Fresh Produce!'),
      'Big Weekend Mega Discount',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'مثال: خصم 50% على المنتجات الطازجة لفترة محدودة!'),
      'تخفيضات نهاية الأسبوع الكبرى',
    );
    await tester.pumpAndSettle();

    // Verify Live Preview updated
    expect(find.text('Big Weekend Mega Discount'), findsNWidgets(2)); // Form + Preview

    // Submit Broadcast
    await tester.tap(find.text('Send Broadcast Now'));
    await tester.pumpAndSettle();

    // Verify Toast/Snackbar and updated list
    expect(find.text('Notification Broadcast Sent!'), findsOneWidget);
    expect(find.text('Big Weekend Mega Discount'), findsOneWidget);
  });

  testWidgets('NotificationsCrudScreen delete confirmation dialog removes record', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([notif1, notif2]),
          ),
        ],
        child: const MaterialApp(
          home: NotificationsCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Delete button for notif2
    final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Delete Notification Log?'), findsOneWidget);
    await tester.tap(find.text('Yes, Delete'));
    await tester.pumpAndSettle();

    // notif2 should no longer be in the list
    expect(find.text('Lulu Weekly Flyer'), findsNothing);
  });

  testWidgets('NotificationsCrudScreen renders cleanly on mobile screen width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([notif1]),
          ),
        ],
        child: const MaterialApp(
          home: NotificationsCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Notification Delivery & Broadcast'), findsOneWidget);
    expect(find.text('Flash 50% Off Deal'), findsOneWidget);

    // Tap Compose on Mobile
    await tester.tap(find.text('Compose & Broadcast Notification'));
    await tester.pumpAndSettle();

    // Verify Modal opens cleanly on mobile
    expect(find.text('Link Related Deal / Entity'), findsOneWidget);
    expect(find.text('Live Alert Preview'), findsOneWidget);
    expect(find.text('Send Broadcast Now'), findsOneWidget);
  });
}
