import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/dashboard/admin_dashboard_screen.dart';
import 'package:dealspot_flutter/core/services/auth_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(AdminUser admin)
      : super(AuthState(
          currentAdmin: admin,
          isLoading: false,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const storeManager = AdminUser(
    id: 5,
    fullName: 'Tariq Al-Ghamdi',
    email: 'tariq@lulu.com',
    role: 'STORE_MANAGER',
    isActive: 1,
    storeId: 10,
  );

  const superAdmin = AdminUser(
    id: 1,
    fullName: 'System Administrator',
    email: 'admin@dealspot.com',
    role: 'SUPER_ADMIN',
    isActive: 1,
  );

  testWidgets('AdminDashboardScreen renders Store Dashboard matching Angular implementation exactly', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(storeManager)),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Welcome Section Header (.dash-welcome)
    expect(find.text('Welcome, Tariq Al-Ghamdi'), findsOneWidget);
    expect(find.text('Store Manager'), findsOneWidget);
    expect(
      find.text('Control panel and quick management center for catalogs, retail partners, promotions, and system operations.'),
      findsOneWidget,
    );

    // 2. Main Management Modules Grid (.modules-section)
    expect(find.text('System Modules & Catalogs'), findsOneWidget);
    expect(find.text('Retail Stores'), findsOneWidget);
    expect(find.text('Partner Brands'), findsOneWidget);
    expect(find.text('Product Catalog'), findsOneWidget);
    expect(find.text('Promotions & Deals'), findsOneWidget);
    expect(find.text('Brochures & Flyers'), findsOneWidget);
    expect(find.text('Promo Coupons'), findsOneWidget);
    expect(find.text('Partner Requests'), findsOneWidget);
    expect(find.text('Broadcast Alerts'), findsOneWidget);
    expect(find.text('Cities & Locations'), findsOneWidget);
    expect(find.text('Departments & Categories'), findsOneWidget);
    expect(find.text('Staff & Admins'), findsOneWidget);
    expect(find.text('Audit & History Logs'), findsOneWidget);

    // 3. Fast Creation Actions Bar (.quick-creation-panel)
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Add New Offer'), findsOneWidget);
    expect(find.text('Upload New Flyer'), findsOneWidget);
    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('Create Coupon'), findsOneWidget);
    expect(find.text('Broadcast Notification'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen renders Super Admin dashboard matching Angular', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(superAdmin)),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome, System Administrator'), findsOneWidget);
    expect(find.text('Super Administrator'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen renders cleanly on mobile screen width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier(storeManager)),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome, Tariq Al-Ghamdi'), findsOneWidget);
    expect(find.text('Store Manager'), findsOneWidget);
    expect(find.text('System Modules & Catalogs'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
