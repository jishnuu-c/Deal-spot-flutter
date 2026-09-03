import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/dashboard/admin_layout.dart';
import 'package:dealspot_flutter/features/admin/presentation/dashboard/admin_dashboard_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/stores_crud_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/branches_crud_screen.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/models/models.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Test StoresCrudScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StoresCrudScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(StoresCrudScreen), findsOneWidget);
  });

  testWidgets('Test BranchesCrudScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BranchesCrudScreen(storeId: 1),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BranchesCrudScreen), findsOneWidget);
  });
}
