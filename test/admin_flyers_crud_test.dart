import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/flyers_crud_screen.dart';
import 'package:dealspot_flutter/core/services/flyer_repository.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/auth_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

void main() {
  testWidgets('FlyersCrudScreen renders header, stats, and mobile flyer cards matching Angular', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testStore = Store(
      id: 1,
      nameEn: 'Lulu Hypermarket',
      nameAr: 'لولو هايبرماركت',
      cityId: 1,
      categoryId: 1,
      logoUrl: '',
      isVerified: 1,
      isActive: 1,
    );

    final testCity = City(
      id: 1,
      nameEn: 'Dubai',
      nameAr: 'دبي',
      regionCode: 'DXB',
      latitude: 25.2,
      longitude: 55.27,
      isActive: 1,
    );

    final testFlyer = Flyer(
      id: 2,
      storeId: 1,
      cityId: 1,
      titleEn: 'Weekly Super Saver Deals',
      titleAr: 'عروض التوفير الأسبوعية الكبرى',
      coverImageUrl: 'https://example.com/cover.jpg',
      totalPages: 4,
      validFrom: '2026-09-12',
      validUntil: '2026-09-19',
      isActive: 1,
      viewCount: 0,
      store: testStore,
      city: testCity,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flyerRepositoryProvider.overrideWith((ref) => MockFlyerNotifier([testFlyer])),
          storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier([testStore])),
          cityRepositoryProvider.overrideWith((ref) => MockCityNotifier([testCity])),
          authProvider.overrideWith((ref) => MockAuthNotifier()),
        ],
        child: const MaterialApp(
          home: FlyersCrudScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Header
    expect(find.text('Store Flyers & Catalogues'), findsOneWidget);
    expect(find.text('Add New Flyer'), findsOneWidget);

    // Verify 4 Stat Cards
    expect(find.text('Total Catalogues'), findsOneWidget);
    expect(find.text('Active & Valid'), findsWidgets);
    expect(find.text('Expired Flyers'), findsWidgets);
    expect(find.text('Total Views'), findsOneWidget);

    // Verify Search & Dropdowns
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All Stores'), findsOneWidget);
    expect(find.text('All Cities'), findsOneWidget);
    expect(find.text('All Statuses'), findsOneWidget);

    // Verify Flyer Mobile Card Item
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('Weekly Super Saver Deals'), findsOneWidget);
    expect(find.text('Lulu Hypermarket'), findsOneWidget);
    expect(find.text('Dubai'), findsOneWidget);
    expect(find.text('4 pages'), findsOneWidget);
    expect(find.text('0 views'), findsOneWidget);
    expect(find.text('2026-09-12'), findsOneWidget);
    expect(find.text('2026-09-19'), findsOneWidget);
    expect(find.text('Manage Pages'), findsOneWidget);
  });
}

class MockFlyerNotifier extends StateNotifier<FlyerState> implements FlyerNotifier {
  MockFlyerNotifier(List<Flyer> flyers)
      : super(FlyerState(flyers: flyers, pages: const [], isLoading: false));

  @override
  Future<void> fetchFlyers({int? storeId}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  MockStoreNotifier(List<Store> stores)
      : super(StoreState(stores: stores, branches: const [], followedStoreIds: const [], isLoading: false));

  @override
  Future<void> fetchStores() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier(List<City> cities)
      : super(CityState(cities: cities, isLoading: false));

  @override
  Future<void> fetchCities() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier()
      : super(const AuthState(
          currentAdmin: AdminUser(
            id: 1,
            fullName: 'Admin',
            email: 'admin@dealspot.com',
            role: 'SUPER_ADMIN',
            isActive: 1,
          ),
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
