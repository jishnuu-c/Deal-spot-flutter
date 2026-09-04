import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/stores_crud_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/branches_crud_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/products_crud_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/brands_crud_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/admin_product_detail_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/product_specs_crud_screen.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/category_repository.dart';
import 'package:dealspot_flutter/core/services/product_repository.dart';
import 'package:dealspot_flutter/core/services/brand_repository.dart';
import 'package:dealspot_flutter/models/models.dart';
import 'package:dealspot_flutter/models/brand.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Test StoresCrudScreen renders properly without blank screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = Store(
      id: 1,
      nameEn: 'Panda',
      nameAr: 'بندة',
      cityId: 1,
      categoryId: 1,
      logoUrl: '',
      isActive: 1,
      isVerified: 1,
      featured: true,
      cityNameEn: 'Riyadh',
      cityNameAr: 'الرياض',
      categoryNameEn: 'Supermarket',
      categoryNameAr: 'سوبرماركت',
    );

    final city = City(
      id: 1,
      nameEn: 'Riyadh',
      nameAr: 'الرياض',
      regionCode: 'RUH',
      latitude: 24.7136,
      longitude: 46.6753,
      isActive: 1,
    );

    final category = Category(
      id: 1,
      nameEn: 'Supermarket',
      nameAr: 'سوبرماركت',
      iconSlug: 'store',
      sortOrder: 1,
      isActive: 1,
    );

    final container = ProviderContainer(
      overrides: [
        storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier([store])),
        cityRepositoryProvider.overrideWith((ref) => MockCityNotifier([city])),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier([category])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: StoresCrudScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(StoresCrudScreen), findsOneWidget);
    expect(find.text('Panda'), findsOneWidget);
    expect(find.byIcon(Icons.domain), findsOneWidget);
  });

  testWidgets('Test BranchesCrudScreen renders properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final branch = StoreBranch(
      id: 1,
      storeId: 1,
      cityId: 1,
      branchName: 'Olaya Branch',
      latitude: 24.7136,
      longitude: 46.6753,
      openTime: '08:00:00',
      closeTime: '22:00:00',
      isActive: 1,
      addressLine: 'Olaya St',
      contactPhone: '+966500000000',
    );

    final city = City(
      id: 1,
      nameEn: 'Riyadh',
      nameAr: 'الرياض',
      regionCode: 'RUH',
      latitude: 24.7136,
      longitude: 46.6753,
      isActive: 1,
    );

    final container = ProviderContainer(
      overrides: [
        storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier([], [branch])),
        cityRepositoryProvider.overrideWith((ref) => MockCityNotifier([city])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: BranchesCrudScreen(storeId: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(BranchesCrudScreen), findsOneWidget);
    expect(find.text('Olaya Branch'), findsOneWidget);

    // Tap Add New Branch button to open modal
    await tester.tap(find.text('Add New Branch'));
    await tester.pumpAndSettle();

    expect(find.text('Add Store Branch'), findsOneWidget);
    expect(find.text('Select Branch Location on Map *'), findsOneWidget);
    expect(find.text('Open 24 Hours (24/7)'), findsOneWidget);
  });

  testWidgets('Test ProductsCrudScreen renders properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = Product(
      id: 1,
      nameEn: 'Fresh Milk 1L',
      nameAr: 'حليب طازج 1 لتر',
      brand: 'Almarai',
      brandAr: 'المراعي',
      sku: 'ALM-1L',
      barcode: '6281007010014',
      primaryImageUrl: '',
      unit: 'L',
      unitSize: 1.0,
      categoryId: 1,
      isActive: 1,
    );

    final category = Category(
      id: 1,
      nameEn: 'Dairy',
      nameAr: 'ألبان',
      iconSlug: 'category',
      sortOrder: 1,
      isActive: 1,
    );

    final brand = Brand(
      id: 1,
      nameEn: 'Almarai',
      nameAr: 'المراعي',
      logoUrl: '',
      active: true,
      categories: [],
    );

    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWith((ref) => MockProductNotifier([product])),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier([category])),
        brandRepositoryProvider.overrideWith((ref) => MockBrandNotifier([brand])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ProductsCrudScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ProductsCrudScreen), findsOneWidget);
    expect(find.text('Fresh Milk 1L'), findsOneWidget);

    // Tap Add Product button
    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();

    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('Product Names'), findsOneWidget);
    expect(find.text('Codes & Measurements'), findsOneWidget);
    expect(find.text('Active Product'), findsOneWidget);
  });

  testWidgets('Test BrandsCrudScreen renders and opens edit modal properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final brand = Brand(
      id: 1,
      nameEn: 'Samsung',
      nameAr: 'سامسونج',
      logoUrl: '',
      websiteUrl: 'https://www.samsung.com',
      descriptionEn: 'Electronics',
      descriptionAr: 'إلكترونيات',
      featured: true,
      active: true,
      categories: [],
    );

    final container = ProviderContainer(
      overrides: [
        brandRepositoryProvider.overrideWith((ref) => MockBrandNotifier([brand])),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: BrandsCrudScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(BrandsCrudScreen), findsOneWidget);
    expect(find.text('Samsung'), findsOneWidget);

    // Tap edit icon to open modal
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit Brand Partner'), findsOneWidget);
    expect(find.text('Official Website'), findsOneWidget);
    expect(find.text('Assigned Categories'), findsOneWidget);
    expect(find.text('Active Partner'), findsOneWidget);
    expect(find.text('Featured Brand'), findsOneWidget);
  });
  testWidgets('Test AdminProductDetailScreen renders properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = Product(
      id: 1,
      nameEn: 'Fresh Milk 1L',
      nameAr: 'حليب طازج 1 لتر',
      brand: 'Almarai',
      brandAr: 'المراعي',
      sku: 'ALM-1L',
      barcode: '6281007010014',
      primaryImageUrl: '',
      unit: 'L',
      unitSize: 1.0,
      categoryId: 1,
      isActive: 1,
    );

    final category = Category(
      id: 1,
      nameEn: 'Dairy',
      nameAr: 'ألبان',
      iconSlug: 'category',
      sortOrder: 1,
      isActive: 1,
    );

    final brand = Brand(
      id: 1,
      nameEn: 'Almarai',
      nameAr: 'المراعي',
      logoUrl: '',
      active: true,
      categories: [],
    );

    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWith((ref) => MockProductNotifier([product])),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier([category])),
        brandRepositoryProvider.overrideWith((ref) => MockBrandNotifier([brand])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: AdminProductDetailScreen(productId: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AdminProductDetailScreen), findsOneWidget);
    expect(find.text('Fresh Milk 1L'), findsWidgets);
    expect(find.text('General Product Information'), findsOneWidget);
  });

  testWidgets('Test ProductSpecsCrudScreen renders properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spec = ProductDetail(
      id: 1,
      productId: 1,
      attrKeyEn: 'Storage',
      attrKeyAr: 'السعة',
      attrValueEn: '256 GB',
      attrValueAr: '256 جيجابايت',
      sortOrder: 1,
    );

    final product = Product(
      id: 1,
      nameEn: 'iPhone 15 Pro',
      nameAr: 'آيفون 15 برو',
      brand: 'Apple',
      brandAr: 'أبل',
      sku: 'IPH-15P',
      barcode: '1234567890123',
      primaryImageUrl: '',
      unit: 'EACH',
      unitSize: 1.0,
      categoryId: 1,
      isActive: 1,
      details: [spec],
    );

    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWith((ref) => MockProductNotifier([product], [spec])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ProductSpecsCrudScreen(productId: 1),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ProductSpecsCrudScreen), findsOneWidget);
    expect(find.text('Technical Specifications'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
  });
}

class MockStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  final List<StoreBranch> _testBranches;
  MockStoreNotifier([List<Store> initialStores = const [], this._testBranches = const []])
      : super(StoreState(stores: initialStores, branches: _testBranches, followedStoreIds: const [], isLoading: false));

  @override
  List<StoreBranch> getBranchesForStore(int storeId) => _testBranches.where((b) => b.storeId == storeId).toList();

  @override
  Store? getStoreById(int id) => state.stores.where((s) => s.id == id).firstOrNull;

  @override
  Future<void> fetchStores() async {}

  Future<void> fetchBranches() async {}

  @override
  Future<List<StoreBranch>> fetchBranchesForStore(int storeId) async => getBranchesForStore(storeId);

  @override
  Future<Store?> fetchStoreById(int id) async => getStoreById(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier(List<City> initialCities)
      : super(CityState(cities: initialCities, selectedCity: null, isLoading: false));

  @override
  Future<void> fetchCities() async {}

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

class MockProductNotifier extends StateNotifier<ProductState> implements ProductNotifier {
  MockProductNotifier(List<Product> initialProducts, [List<ProductDetail> initialDetails = const []])
      : super(ProductState(products: initialProducts, details: initialDetails, images: const [], isLoading: false));

  @override
  List<Product> getProducts() => state.products;

  @override
  Product? getProductById(int id) {
    final p = state.products.where((p) => p.id == id).firstOrNull;
    if (p == null) return null;
    return p.copyWith(details: state.details.where((d) => d.productId == id).toList());
  }

  @override
  Future<void> fetchProducts() async {}

  @override
  Future<PagedProductResult> getPagedProducts({
    int page = 0,
    int size = 20,
    String? search,
    int? categoryId,
    int? brandId,
    String sortBy = 'createdAt',
    String direction = 'desc',
  }) async {
    var list = state.products;
    if (search != null && search.isNotEmpty) {
      list = list.where((p) => p.nameEn.toLowerCase().contains(search.toLowerCase()) || p.nameAr.contains(search)).toList();
    }
    if (categoryId != null) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (brandId != null) {
      list = list.where((p) => p.brandId == brandId).toList();
    }
    return PagedProductResult(
      content: list,
      totalElements: list.length,
      totalPages: 1,
      number: page,
    );
  }

  @override
  Future<Product?> fetchProductById(int id) async => getProductById(id);

  @override
  Future<List<ProductDetail>> fetchProductDetails(int productId) async =>
      state.details.where((d) => d.productId == productId).toList();

  @override
  Future<List<AttributeKey>> fetchAttributeKeys() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBrandNotifier extends StateNotifier<BrandState> implements BrandNotifier {
  MockBrandNotifier(List<Brand> initialBrands)
      : super(BrandState(brands: initialBrands, isLoading: false));

  @override
  Future<void> fetchBrands() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
