import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/flyers/presentation/flyer_list_screen.dart';
import 'package:dealspot_flutter/features/flyers/presentation/flyer_viewer_screen.dart';
import 'package:dealspot_flutter/core/services/flyer_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier(List<City> cities) : super(CityState(cities: cities, selectedCity: null));

  @override
  Future<void> fetchCities() async {}

  @override
  Future<void> selectCity(City? city) async {}

  @override
  Future<void> clearCityFilter() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFlyerNotifier extends StateNotifier<FlyerState> implements FlyerNotifier {
  MockFlyerNotifier(List<Flyer> flyers, List<FlyerPage> pages)
      : super(FlyerState(flyers: flyers, pages: pages, isLoading: false));

  @override
  Future<void> fetchFlyers({int? storeId}) async {}

  @override
  Future<Flyer?> fetchFlyerById(int id) async => null;

  @override
  Future<List<FlyerPage>> fetchFlyerPages(int flyerId) async => [];

  @override
  List<Flyer> getFlyers([int? cityId]) {
    var list = state.flyers.where((f) => f.isActive == 1).toList();
    if (cityId != null && cityId > 0) {
      list = list.where((f) => f.cityId == 0 || f.cityId == cityId).toList();
    }
    return list;
  }

  @override
  Flyer? getFlyerById(int id) {
    return state.flyers.where((f) => f.id == id).firstOrNull;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  MockStoreNotifier(List<Store> stores)
      : super(StoreState(stores: stores, branches: [], followedStoreIds: [], isLoading: false));

  @override
  Future<void> fetchStores() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleCities = <City>[
    const City(id: 1, nameEn: 'Riyadh', nameAr: 'الرياض', regionCode: '01', latitude: 24.7136, longitude: 46.6753, isActive: 1),
  ];

  final sampleStores = <Store>[
    const Store(
      id: 1,
      cityId: 1,
      categoryId: 1,
      nameEn: 'Lulu Hypermarket',
      nameAr: 'لولو هايبرماركت',
      logoUrl: '',
      isVerified: 1,
      isActive: 1,
    ),
  ];

  final samplePages = <FlyerPage>[
    const FlyerPage(id: 1, flyerId: 1, pageNumber: 1, imageUrl: '', thumbUrl: ''),
    const FlyerPage(id: 2, flyerId: 1, pageNumber: 2, imageUrl: '', thumbUrl: ''),
  ];

  final sampleFlyers = <Flyer>[
    Flyer(
      id: 1,
      storeId: 1,
      cityId: 1,
      titleEn: 'Weekend Big Super Saver Flyer',
      titleAr: 'عروض نهاية الأسبوع الكبرى',
      coverImageUrl: '',
      totalPages: 8,
      validFrom: '2026-09-01',
      validUntil: '2026-12-31',
      isActive: 1,
      viewCount: 250,
      store: sampleStores[0],
      pages: samplePages,
    ),
  ];

  testWidgets('FlyerListScreen renders flyer cards properly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityRepositoryProvider.overrideWith((ref) => MockCityNotifier(sampleCities)),
          flyerRepositoryProvider.overrideWith((ref) => MockFlyerNotifier(sampleFlyers, samplePages)),
          storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier(sampleStores)),
        ],
        child: const MaterialApp(
          home: FlyerListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekend Big Super Saver Flyer'), findsOneWidget);
    expect(find.text('Lulu Hypermarket'), findsOneWidget);
    expect(find.text('8 Pages'), findsWidgets);
  });

  testWidgets('FlyerViewerScreen renders flyer viewer and pages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flyerRepositoryProvider.overrideWith((ref) => MockFlyerNotifier(sampleFlyers, samplePages)),
        ],
        child: const MaterialApp(
          home: FlyerViewerScreen(flyerId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekend Big Super Saver Flyer'), findsOneWidget);
    expect(find.text('Lulu Hypermarket'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });
}
