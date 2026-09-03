import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/stores_crud_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/branches_crud_screen.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/products_crud_screen.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/core/services/category_repository.dart';
import 'package:dealspot_flutter/core/services/product_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

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

    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWith((ref) => MockProductNotifier([product])),
        categoryRepositoryProvider.overrideWith((ref) => MockCategoryNotifier([category])),
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockCityNotifier(List<City> initialCities)
      : super(CityState(cities: initialCities, selectedCity: null, isLoading: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryNotifier extends StateNotifier<List<Category>> implements CategoryNotifier {
  MockCategoryNotifier(List<Category> initialCategories) : super(initialCategories);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockProductNotifier extends StateNotifier<ProductState> implements ProductNotifier {
  MockProductNotifier(List<Product> initialProducts)
      : super(ProductState(products: initialProducts, details: const [], images: const [], isLoading: false));

  @override
  List<Product> getProducts() => state.products;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
