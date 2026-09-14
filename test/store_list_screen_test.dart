import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/stores/presentation/store_list_screen.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/category_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier(List<City> cities) : super(CityState(cities: cities, selectedCity: null));

  @override
  Future<void> fetchCities() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryNotifier extends StateNotifier<List<Category>> implements CategoryNotifier {
  MockCategoryNotifier(List<Category> categories) : super(categories);

  @override
  Future<void> fetchCategories() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  MockStoreNotifier(List<Store> stores, List<int> followed)
      : super(StoreState(stores: stores, branches: [], followedStoreIds: followed, isLoading: false));

  @override
  Future<void> fetchStores() async {}

  @override
  Future<void> fetchFollowedStores() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleCities = <City>[
    const City(id: 1, nameEn: 'Riyadh', nameAr: 'الرياض', regionCode: '01', latitude: 24.7136, longitude: 46.6753, isActive: 1),
    const City(id: 2, nameEn: 'Jeddah', nameAr: 'جدة', regionCode: '02', latitude: 21.5433, longitude: 39.1728, isActive: 1),
  ];

  final sampleCategories = <Category>[
    const Category(id: 1, nameEn: 'Supermarket', nameAr: 'سوبرماركت', iconSlug: 'shopping_cart', isActive: 1, sortOrder: 1),
    const Category(id: 2, nameEn: 'Electronics', nameAr: 'إلكترونيات', iconSlug: 'devices', isActive: 1, sortOrder: 2),
  ];

  final sampleStores = <Store>[
    const Store(
      id: 1,
      cityId: 1,
      categoryId: 1,
      nameEn: 'Lulu Hypermarket',
      nameAr: 'لولو هايبرماركت',
      logoUrl: '',
      cityNameEn: 'Riyadh',
      categoryNameEn: 'Supermarket',
      isVerified: 1,
      isActive: 1,
      followersCount: 120,
    ),
    const Store(
      id: 2,
      cityId: 2,
      categoryId: 2,
      nameEn: 'Jarir Bookstore',
      nameAr: 'مكتبة جرير',
      logoUrl: '',
      cityNameEn: 'Jeddah',
      categoryNameEn: 'Electronics',
      isVerified: 0,
      isActive: 1,
      followersCount: 85,
    ),
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        cityRepositoryProvider.overrideWith((ref) => MockCityNotifier(sampleCities)),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier(sampleCategories)),
        storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier(sampleStores, [1])),
      ],
      child: const MaterialApp(
        home: StoreListScreen(),
      ),
    );
  }

  testWidgets('StoreListScreen renders Desktop Sidebar and Store Cards matching Angular', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify filter sidebar elements
    expect(find.text('Filter Stores'), findsOneWidget);
    expect(find.text('Search Store'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Verified Stores Only'), findsOneWidget);

    // Verify stores rendered
    expect(find.text('Lulu Hypermarket'), findsOneWidget);
    expect(find.text('Jarir Bookstore'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('120 Followers'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('StoreListScreen renders Mobile Filter Bar on narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Filter & Search'), findsOneWidget);
    expect(find.text('2 stores'), findsOneWidget);
  });
}
