import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/dashboard/admin_layout.dart';
import 'package:dealspot_flutter/core/services/auth_repository.dart';
import 'package:dealspot_flutter/core/services/notification_repository.dart';
import 'package:dealspot_flutter/core/utils/translation_service.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(AdminUser admin)
      : super(AuthState(
          currentAdmin: admin,
          isLoading: false,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> logout() async {
    state = const AuthState();
  }
}

class MockTranslationNotifier extends StateNotifier<AppLanguage> implements TranslationNotifier {
  MockTranslationNotifier(super.initialLang);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void toggleLanguage() {
    state = state == AppLanguage.en ? AppLanguage.ar : AppLanguage.en;
  }
}

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
  Future<void> markAllAsRead([int? userId]) async {
    final updated = state.notifications.map((n) => n.copyWith(isRead: 1)).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  @override
  Future<void> markAsRead(int id) async {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: 1);
      return n;
    }).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => n.isRead == 0).length,
    );
  }
}

void main() {
  const superAdmin = AdminUser(
    id: 1,
    fullName: 'System Administrator',
    email: 'admin@dealspot.com',
    role: 'SUPER_ADMIN',
    isActive: 1,
  );

  const testNotif1 = Notification(
    id: 1,
    userId: 101,
    type: 'FLASH_DEAL',
    channel: 'PUSH',
    titleEn: 'Mega Flash Sale 50% Off',
    titleAr: 'تخفيضات فلاش 50%',
    bodyEn: 'Limited time discounts on all brands.',
    bodyAr: 'خصومات حصرية لفترة محدودة.',
    isRead: 0,
    sentAt: '2026-09-12T14:00:00',
  );

  const testNotif2 = Notification(
    id: 2,
    userId: 102,
    type: 'COUPON_ALERT',
    channel: 'EMAIL',
    titleEn: 'VIP Discount Voucher',
    titleAr: 'قسيمة خصم كبار الشخصيات',
    bodyEn: 'Use coupon code VIP20 at checkout.',
    bodyAr: 'استخدم كود الخصم VIP20 عند الشراء.',
    isRead: 0,
    sentAt: '2026-09-12T12:30:00',
  );

  testWidgets('Admin TopBar renders with desktop layout, profile info, and controls', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(superAdmin)),
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([testNotif1, testNotif2]),
          ),
        ],
        child: const MaterialApp(
          home: AdminLayout(
            child: Text('Admin Content Viewport'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Page Title & Content - Always "Dashboard Control" matching Angular
    expect(find.text('Dashboard Control'), findsOneWidget);
    expect(find.text('Admin Content Viewport'), findsOneWidget);

    // 2. Admin User Information
    expect(find.text('System Administrator'), findsOneWidget);
    expect(find.text('Super Administrator'), findsOneWidget);

    // 3. Notification Badge Count (2 unread)
    expect(find.text('2'), findsOneWidget);

    // 4. Language Toggle ('AR' button in English mode)
    expect(find.text('AR'), findsOneWidget);

    // 5. Logout Button
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });

  testWidgets('Admin TopBar Notification dropdown popover opens, marks all read, and shows details', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(superAdmin)),
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([testNotif1, testNotif2]),
          ),
        ],
        child: const MaterialApp(
          home: AdminLayout(
            child: Text('Admin Content Viewport'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Notification Bell
    await tester.tap(find.byIcon(Icons.notifications_active_rounded));
    await tester.pumpAndSettle();

    // Verify Notification Popover Header
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('2 New'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);

    // Verify Notification Items in Body
    expect(find.text('Mega Flash Sale 50% Off'), findsOneWidget);
    expect(find.text('Limited time discounts on all brands.'), findsOneWidget);
    expect(find.text('VIP Discount Voucher'), findsOneWidget);

    // Verify Popover Footer
    expect(find.text('View All Notifications & Broadcast'), findsOneWidget);

    // Tap "Mark all as read"
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();

    // Unread count badge should disappear / update
    expect(find.text('2 New'), findsNothing);
  });

  testWidgets('Admin TopBar renders on mobile screens with hamburger menu', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(superAdmin)),
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([]),
          ),
        ],
        child: const MaterialApp(
          home: AdminLayout(
            child: Text('Admin Content Viewport'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Hamburger button should be present on mobile
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.text('Dashboard Control'), findsOneWidget);

    // Tap Hamburger button to open Drawer
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    // Drawer should open showing Brand and Menu Items
    expect(find.text('DealSpot KSA'), findsOneWidget);
    expect(find.text('Control Panel'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Partner Requests'), findsOneWidget);
  });

  testWidgets('Admin TopBar always renders Arabic title "لوحة الإدارة" in Arabic mode', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(superAdmin)),
          translationProvider.overrideWith((ref) => MockTranslationNotifier(AppLanguage.ar)),
          notificationRepositoryProvider.overrideWith(
            (ref) => MockNotificationNotifier([]),
          ),
        ],
        child: const MaterialApp(
          home: AdminLayout(
            child: Text('محتوى لوحة الإدارة'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Title in Arabic must always be "لوحة الإدارة"
    expect(find.text('لوحة الإدارة'), findsOneWidget);
  });
}
