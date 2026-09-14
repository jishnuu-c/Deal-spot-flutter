import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/routes/app_router.dart';
import 'package:dealspot_flutter/features/stores/presentation/store_list_screen.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/category_repository.dart';
import 'package:dealspot_flutter/core/services/offer_repository.dart';
import 'package:dealspot_flutter/core/services/flyer_repository.dart';
import 'package:dealspot_flutter/core/services/brand_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier() : super(const CityState(cities: [
    City(id: 1, nameEn: 'Riyadh', nameAr: 'الرياض', regionCode: '01', latitude: 24.7136, longitude: 46.6753, isActive: 1),
  ], selectedCity: null));

  @override
  Future<void> fetchCities() async {}

  @override
  Future<void> selectCity(City? city) async {}

  @override
  Future<void> clearCityFilter() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryNotifier extends StateNotifier<List<Category>> implements CategoryNotifier {
  MockCategoryNotifier() : super([
    const Category(id: 1, nameEn: 'Supermarket', nameAr: 'سوبرماركت', iconSlug: 'shopping_cart', isActive: 1, sortOrder: 1),
  ]);

  @override
  Future<void> fetchCategories() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  MockStoreNotifier() : super(const StoreState(stores: [
    Store(
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
  ], branches: [], followedStoreIds: [], isLoading: false));

  @override
  Future<void> fetchStores() async {}

  @override
  Future<void> fetchFollowedStores() async {}

  @override
  List<Store> getFeaturedStores() => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockOfferNotifier extends StateNotifier<OfferState> implements OfferNotifier {
  MockOfferNotifier() : super(const OfferState(offers: [], images: [], savedOfferIds: []));

  @override
  Future<void> fetchOffers({int? storeId, int? cityId, bool? includeExpired}) async {}

  @override
  Future<void> fetchSavedOffers() async {}

  @override
  List<Offer> getFlashDeals({int? cityId}) => [];

  @override
  List<Offer> getFeaturedOffers({int? cityId}) => [];

  @override
  List<Offer> getLatestOffers({int? cityId, int limit = 12}) => [];

  @override
  List<Offer> getOffers([OfferFilters? filters]) => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFlyerNotifier extends StateNotifier<FlyerState> implements FlyerNotifier {
  MockFlyerNotifier() : super(const FlyerState(flyers: [], pages: []));

  @override
  Future<void> fetchFlyers({int? storeId}) async {}

  @override
  List<Flyer> getFlyers([int? cityId]) => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBrandNotifier extends StateNotifier<BrandState> implements BrandNotifier {
  MockBrandNotifier() : super(const BrandState(brands: []));

  @override
  Future<void> fetchBrands() async {}

  @override
  Future<PagedBrandResult> fetchFeaturedBrandsPaged({int page = 0, int size = 15}) async =>
      const PagedBrandResult(content: [], totalElements: 0, totalPages: 0, number: 0, isLast: true);

  @override
  List<Brand> getFeaturedBrands() => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('BottomNavigationBar navigation test to Stores', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        cityRepositoryProvider.overrideWith((ref) => MockCityNotifier()),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier()),
        storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier()),
        offerRepositoryProvider.overrideWith((ref) => MockOfferNotifier()),
        flyerRepositoryProvider.overrideWith((ref) => MockFlyerNotifier()),
        brandRepositoryProvider.overrideWith((ref) => MockBrandNotifier()),
      ],
    );

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Stores destination
    final storesIcon = find.byIcon(Icons.storefront_outlined);
    expect(storesIcon, findsOneWidget);

    await tester.tap(storesIcon);
    await tester.pumpAndSettle();

    // Verify StoreListScreen is rendered
    expect(find.byType(StoreListScreen), findsOneWidget);
    expect(find.text('Lulu Hypermarket'), findsOneWidget);
  });
}
