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

    await tester.pump(const Duration(milliseconds: 500));

    // 1. Welcome Section Header (.dash-welcome)
    expect(find.text('Welcome, Tariq Al-Ghamdi'), findsOneWidget);
    expect(find.text('Store Manager'), findsOneWidget);
    expect(
      find.text('Manage your store catalog, published weekly flyers, discount deals, branch locations, and customer promotions.'),
      findsOneWidget,
    );

    // 2. Main Store Management Tools Section (.modules-section)
    expect(find.text('Store Management Tools'), findsOneWidget);
    expect(find.text('My Store Branches'), findsOneWidget);
    expect(find.text('My Offers & Discounts'), findsOneWidget);
    expect(find.text('My Weekly Flyers & Brochures'), findsOneWidget);
    expect(find.text('Product Items & Catalog'), findsOneWidget);
    expect(find.text('My Promo Coupons'), findsOneWidget);

    // 3. Fast Creation Actions Bar (.quick-creation-panel)
    expect(find.text('Store Quick Actions'), findsOneWidget);
    expect(find.text('Add New Offer'), findsOneWidget);
    expect(find.text('Upload New Flyer'), findsOneWidget);
    expect(find.text('Manage Branches'), findsOneWidget);
    expect(find.text('Create Coupon'), findsOneWidget);
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

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome, System Administrator'), findsOneWidget);
    expect(find.text('Super Administrator'), findsOneWidget);
    expect(find.text('System Modules & Catalogs'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
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

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome, Tariq Al-Ghamdi'), findsOneWidget);
    expect(find.text('Store Manager'), findsOneWidget);
    expect(find.text('Store Management Tools'), findsOneWidget);
    expect(find.text('Store Quick Actions'), findsOneWidget);
  });
}
