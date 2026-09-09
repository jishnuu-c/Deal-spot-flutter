import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealspot_flutter/core/services/admin_user_repository.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/users_crud_screen.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockAdminUserNotifier extends StateNotifier<AdminUserState>
    implements AdminUserNotifier {
  MockAdminUserNotifier(List<AdminUser> admins)
      : super(AdminUserState(admins: admins, isLoading: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> fetchAdmins() async {}

  @override
  Future<AdminUser> createAdmin({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final newAdmin = AdminUser(
      id: state.admins.length + 1,
      fullName: fullName,
      email: email,
      role: role,
      isActive: 1,
      createdAt: '2026-03-01T10:00:00',
    );
    state = state.copyWith(admins: [...state.admins, newAdmin]);
    return newAdmin;
  }

  @override
  Future<AdminUser> toggleAdminStatus(int id) async {
    final current = state.admins.firstWhere((a) => a.id == id);
    final toggled = current.copyWith(isActive: current.isActive == 1 ? 0 : 1);
    state = state.copyWith(
      admins: state.admins.map((a) => a.id == id ? toggled : a).toList(),
    );
    return toggled;
  }

  @override
  Future<void> deleteAdmin(int id) async {
    state = state.copyWith(
      admins: state.admins.where((a) => a.id != id).toList(),
    );
  }
}

void main() {
  final testAdmin1 = AdminUser(
    id: 1,
    fullName: 'Ahmed Al-Shehri',
    email: 'ahmed@dealspot.com',
    role: 'SUPER_ADMIN',
    isActive: 1,
    createdAt: '2026-01-15T12:00:00',
  );

  final testAdmin2 = AdminUser(
    id: 2,
    fullName: 'Sara Al-Otaibi',
    email: 'sara@dealspot.com',
    role: 'CONTENT_MANAGER',
    isActive: 0,
    createdAt: '2026-02-10T14:30:00',
  );

  testWidgets('UsersCrudScreen renders header, stats overview, and table data', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserRepositoryProvider.overrideWith(
            (ref) => MockAdminUserNotifier([testAdmin1, testAdmin2]),
          ),
        ],
        child: const MaterialApp(
          home: UsersCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Admin Team & Staff Management'), findsOneWidget);
    expect(find.text('Register New Staff'), findsOneWidget);

    // Verify Stats Grid
    expect(find.text('Total Staff'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // 2 total staff
    expect(find.text('Active Accounts'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // 1 active, 1 super admin
    expect(find.text('Super Admins'), findsOneWidget);

    // Verify Table Row Data
    expect(find.text('Ahmed Al-Shehri'), findsOneWidget);
    expect(find.text('ahmed@dealspot.com'), findsOneWidget);
    expect(find.text('Super Administrator'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    expect(find.text('Sara Al-Otaibi'), findsOneWidget);
    expect(find.text('sara@dealspot.com'), findsOneWidget);
    expect(find.text('Content Manager'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('UsersCrudScreen opens Registration modal and creates a new admin user', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserRepositoryProvider.overrideWith(
            (ref) => MockAdminUserNotifier([testAdmin1, testAdmin2]),
          ),
        ],
        child: const MaterialApp(
          home: UsersCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Register New Staff button
    await tester.tap(find.text('Register New Staff'));
    await tester.pumpAndSettle();

    // Verify Modal Dialog Opened
    expect(find.text('Register New Staff Member'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Official Work Email'), findsOneWidget);
    expect(find.text('Assigned Role'), findsOneWidget);
    expect(find.text('Initial Password'), findsOneWidget);
    expect(find.text('Generate Random'), findsOneWidget);

    // Enter full name & email
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Tariq Al-Ghamdi'), 'Tariq Al-Ghamdi');
    await tester.enterText(find.widgetWithText(TextFormField, 'staff@dealspot.com'), 'tariq@dealspot.com');
    await tester.pumpAndSettle();

    // Tap Save & Register Admin
    await tester.tap(find.text('Save & Register Admin'));
    await tester.pumpAndSettle();

    // Verify Success Dialog is shown
    expect(find.text('Admin Created!'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify new user is in the table
    expect(find.text('Tariq Al-Ghamdi'), findsOneWidget);
    expect(find.text('tariq@dealspot.com'), findsOneWidget);
  });

  testWidgets('UsersCrudScreen status toggle and delete confirmation dialogs work', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserRepositoryProvider.overrideWith(
            (ref) => MockAdminUserNotifier([testAdmin1, testAdmin2]),
          ),
        ],
        child: const MaterialApp(
          home: UsersCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Active status pill for Ahmed
    await tester.tap(find.text('Active').first);
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Confirm Status Change'), findsOneWidget);
    await tester.tap(find.text('Yes, deactivate'));
    await tester.pumpAndSettle();

    // Now Ahmed is Inactive (both are inactive)
    expect(find.text('Inactive'), findsNWidgets(2));

    // Tap Delete button for Sara
    final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    expect(find.text('Delete Staff Member?'), findsOneWidget);
    await tester.tap(find.text('Yes, Delete Permanently'));
    await tester.pumpAndSettle();

    // Sara should no longer be present
    expect(find.text('Sara Al-Otaibi'), findsNothing);
  });

  testWidgets('UsersCrudScreen renders cleanly on narrow mobile screen width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminUserRepositoryProvider.overrideWith(
            (ref) => MockAdminUserNotifier([testAdmin1]),
          ),
        ],
        child: const MaterialApp(
          home: UsersCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Mobile Elements
    expect(find.text('Admin Team & Staff Management'), findsOneWidget);
    expect(find.text('Ahmed Al-Shehri'), findsOneWidget);
    expect(find.text('Super Administrator'), findsOneWidget);
  });
}
