import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/models/models.dart';
import 'package:dealspot_flutter/core/services/offer_repository.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/category_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/product_repository.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/offers_crud_screen.dart';

class MockOfferNotifier extends StateNotifier<OfferState> implements OfferNotifier {
  MockOfferNotifier(List<Offer> initialOffers)
      : super(OfferState(offers: initialOffers, savedOfferIds: const [], images: const [], isLoading: false));

  @override
  Future<void> fetchOffers({int? storeId, int? cityId, bool? includeExpired}) async {}

  @override
  Future<PagedOfferResult> getPagedOffers({
    int page = 0,
    int size = 20,
    String? search,
    int? categoryId,
    int? storeId,
    int? cityId,
    String? badgeType,
    bool? active,
    String sortBy = 'createdAt',
    String direction = 'desc',
  }) async {
    return PagedOfferResult(
      content: state.offers,
      totalElements: state.offers.length,
      totalPages: 1,
      number: page,
    );
  }

  @override
  Future<bool> extendOffer(int id, [int days = 7]) async {
    return true;
  }

  @override
  Future<void> deleteOffer(int id) async {
    state = state.copyWith(offers: state.offers.where((o) => o.id != id).toList());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  MockStoreNotifier(List<Store> initialStores)
      : super(StoreState(stores: initialStores, branches: const [], followedStoreIds: const [], isLoading: false));

  @override
  Future<void> fetchStores() async {}

  @override
  Store? getStoreById(int id) => state.stores.where((s) => s.id == id).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryNotifier extends StateNotifier<List<Category>> implements CategoryNotifier {
  MockCategoryNotifier(super.initialCategories);

  @override
  Future<void> fetchCategories() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier(List<City> initialCities)
      : super(CityState(cities: initialCities, isLoading: false));

  @override
  Future<void> fetchCities() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockProductNotifier extends StateNotifier<ProductState> implements ProductNotifier {
  MockProductNotifier(List<Product> prods)
      : super(ProductState(products: prods, details: const [], images: const [], isLoading: false));

  @override
  Future<PagedProductResult> getPagedProducts({
    int page = 0,
    int size = 20,
    String? search,
    int? categoryId,
    int? brandId,
    bool? active,
    String sortBy = 'createdAt',
    String direction = 'desc',
  }) async {
    return PagedProductResult(
      content: state.products,
      totalElements: state.products.length,
      totalPages: 1,
      number: page,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Full OffersCrudScreen UI, filters, extend offer, and modal verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = Store(id: 1, nameEn: 'Lulu Hypermarket', nameAr: 'لولو هايبرماركت', cityId: 1, categoryId: 1, logoUrl: '', isActive: 1, isVerified: 1);
    final city = City(id: 1, nameEn: 'Riyadh', nameAr: 'الرياض', regionCode: 'RUH', latitude: 24.7, longitude: 46.7, isActive: 1);
    final category = Category(id: 1, nameEn: 'Electronics', nameAr: 'إلكترونيات', iconSlug: 'devices', sortOrder: 1, isActive: 1);
    final product = Product(
      id: 10,
      nameEn: 'Smart TV 55 Inch',
      nameAr: 'شاشة ذكية 55 بوصة',
      brand: 'Samsung',
      brandAr: 'سامسونج',
      sku: 'SAM-TV-55',
      barcode: '8806091234567',
      primaryImageUrl: '',
      unit: 'piece',
      unitSize: 1.0,
      categoryId: 1,
      isActive: 1,
    );

    final offer = Offer(
      id: 1,
      storeId: 1,
      productId: 10,
      categoryId: 1,
      cityId: 1,
      titleEn: '50% Off 4K Smart TVs',
      titleAr: 'خصم 50% على الشاشات الذكية',
      originalPrice: 2000.0,
      offerPrice: 1000.0,
      discountPct: 50.0,
      badgeType: 'FLASH',
      validFrom: '2026-09-01',
      validUntil: '2026-09-30',
      descriptionEn: 'Huge discount on top tier smart TVs',
      descriptionAr: 'خصم كبير على أحدث الشاشات الذكية',
      isFeatured: 1,
      isFlash: 1,
      isActive: 1,
      viewCount: 150,
      saveCount: 25,
      store: store,
      product: product,
      category: category,
      city: city,
    );

    final container = ProviderContainer(
      overrides: [
        offerRepositoryProvider.overrideWith((ref) => MockOfferNotifier([offer])),
        storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier([store])),
        cityRepositoryProvider.overrideWith((ref) => MockCityNotifier([city])),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier([category])),
        productRepositoryProvider.overrideWith((ref) => MockProductNotifier([product])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: OffersCrudScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header & Toolbar
    expect(find.text('Manage Deals & Promotions'), findsOneWidget);
    expect(find.text('Create Offer'), findsOneWidget);
    expect(find.text('Search by title, store, or category...'), findsOneWidget);
    expect(find.text('All Retail Stores'), findsOneWidget);
    expect(find.text('All Badges'), findsOneWidget);
    expect(find.text('All Statuses'), findsOneWidget);
    expect(find.text('Showing 1 of 1 offers'), findsOneWidget);

    // 2. Verify Offer Card Items
    expect(find.text('50% Off 4K Smart TVs'), findsOneWidget);
    expect(find.text('Lulu Hypermarket'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
    expect(find.text('Riyadh'), findsOneWidget);
    expect(find.text('1000.0 SAR'), findsOneWidget);
    expect(find.text('2000.0 SAR'), findsOneWidget);
    expect(find.text('-50% OFF'), findsOneWidget);
    expect(find.text('FLASH'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // 3. Verify Extend Offer Action Dialog
    await tester.tap(find.byIcon(Icons.more_time));
    await tester.pumpAndSettle();
    expect(find.text('Extend Offer Expiration?'), findsOneWidget);
    expect(find.text('Yes, Extend (+7 Days)'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 4. Verify Open Edit Modal
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit Promotion Deal'), findsOneWidget);
    expect(find.text('Offer Title (EN) *'), findsOneWidget);
    expect(find.text('Offer Title (AR) *'), findsOneWidget);
    expect(find.text('Catalog Linked Product (Optional)'), findsOneWidget);
    expect(find.text('Smart TV 55 Inch'), findsOneWidget);
    expect(find.text('Original Price (SAR) *'), findsOneWidget);
    expect(find.text('Offer Price (SAR) *'), findsOneWidget);
    expect(find.text('Discount % (Auto Calculated)'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Promotion Badge'), findsOneWidget);
    expect(find.text('Valid From *'), findsOneWidget);
    expect(find.text('Valid Until *'), findsOneWidget);
    expect(find.text('Offer Promotional Images'), findsOneWidget);
    expect(find.text('Set as Featured Deal'), findsOneWidget);
    expect(find.text('Set as Flash Deal (Limited Time)'), findsOneWidget);
    expect(find.text('Active Status'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 5. Verify Delete Dialog
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Yes, Delete!'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
