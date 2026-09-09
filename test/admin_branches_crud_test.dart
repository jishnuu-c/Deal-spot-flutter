import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/branches_crud_screen.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/city_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  final testStore = Store(
    id: 1,
    nameEn: 'HyperPanda Superstore',
    nameAr: 'هايبربندة',
    cityId: 1,
    categoryId: 1,
    logoUrl: '',
    isActive: 1,
    isVerified: 1,
    featured: true,
  );

  final testCity1 = City(
    id: 1,
    nameEn: 'Riyadh',
    nameAr: 'الرياض',
    regionCode: 'RUH',
    latitude: 24.7136,
    longitude: 46.6753,
    isActive: 1,
  );

  final testCity2 = City(
    id: 2,
    nameEn: 'Jeddah',
    nameAr: 'جدة',
    regionCode: 'JED',
    latitude: 21.5433,
    longitude: 39.1728,
    isActive: 1,
  );

  final testBranches = [
    const StoreBranch(
      id: 101,
      storeId: 1,
      cityId: 1,
      branchName: 'Olaya Main Branch',
      latitude: 24.7136,
      longitude: 46.6753,
      openTime: '08:00:00',
      closeTime: '23:00:00',
      isActive: 1,
      addressLine: 'King Fahd Rd, Building 12',
      addressEn: 'King Fahd Rd, Building 12',
      addressAr: 'طريق الملك فهد، مبنى 12',
      contactPhone: '+966 11 123 4567',
    ),
    const StoreBranch(
      id: 102,
      storeId: 1,
      cityId: 2,
      branchName: 'Tahlia Mall Branch',
      latitude: 21.5433,
      longitude: 39.1728,
      openTime: '00:00:00',
      closeTime: '23:59:59',
      isActive: 1,
      addressLine: 'Tahlia St',
      addressEn: 'Tahlia St',
      addressAr: 'شارع التحلية',
      contactPhone: '+966 12 987 6543',
    ),
  ];

  testWidgets('BranchesCrudScreen renders desktop table with exact headers, stats, and search toolbar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        storeRepositoryProvider.overrideWith((ref) => MockBranchesStoreNotifier([testStore], testBranches)),
        cityRepositoryProvider.overrideWith((ref) => MockBranchesCityNotifier([testCity1, testCity2])),
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

    // Verify Header
    expect(find.text('Branch Management'), findsOneWidget);
    expect(find.textContaining('Branches for'), findsOneWidget);
    expect(find.text('Add New Branch'), findsOneWidget);

    // Verify Stats
    expect(find.text('Total Branches'), findsOneWidget);
    expect(find.text('Active Branches'), findsOneWidget);
    expect(find.text('24/7 Open Branches'), findsOneWidget);

    // Verify Table Rows
    expect(find.text('Olaya Main Branch'), findsOneWidget);
    expect(find.text('Tahlia Mall Branch'), findsOneWidget);
    expect(find.text('#101'), findsOneWidget);
    expect(find.text('#102'), findsOneWidget);
    expect(find.text('24/7'), findsOneWidget);
  });

  testWidgets('BranchesCrudScreen opens Add Branch modal with 4 sections and presets', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        storeRepositoryProvider.overrideWith((ref) => MockBranchesStoreNotifier([testStore], testBranches)),
        cityRepositoryProvider.overrideWith((ref) => MockBranchesCityNotifier([testCity1, testCity2])),
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

    // Tap Add New Branch button
    await tester.tap(find.text('Add New Branch'));
    await tester.pumpAndSettle();

    expect(find.text('Add Store Branch'), findsOneWidget);
    expect(find.text('Basic Branch Information'), findsOneWidget);
    expect(find.text('Map Location & Contact'), findsOneWidget);
    expect(find.text('Operating Schedule'), findsOneWidget);
    expect(find.text('Open 24 Hours (24/7)'), findsOneWidget);
    expect(find.text('Branch Active & Published'), findsOneWidget);
    expect(find.text('Save Branch'), findsOneWidget);
  });

  testWidgets('BranchesCrudScreen renders responsive cards on mobile screen width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        storeRepositoryProvider.overrideWith((ref) => MockBranchesStoreNotifier([testStore], testBranches)),
        cityRepositoryProvider.overrideWith((ref) => MockBranchesCityNotifier([testCity1, testCity2])),
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

    expect(find.text('Olaya Main Branch'), findsOneWidget);
    expect(find.text('Tahlia Mall Branch'), findsOneWidget);
    expect(find.text('Open Map'), findsWidgets);
  });
}

class MockBranchesStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  final List<StoreBranch> _testBranches;
  MockBranchesStoreNotifier([List<Store> initialStores = const [], this._testBranches = const []])
      : super(StoreState(stores: initialStores, branches: _testBranches, followedStoreIds: const [], isLoading: false));

  @override
  List<StoreBranch> getBranchesForStore(int storeId) => _testBranches.where((b) => b.storeId == storeId).toList();

  @override
  Store? getStoreById(int id) => state.stores.where((s) => s.id == id).firstOrNull;

  @override
  Future<void> fetchStores() async {}

  @override
  Future<List<StoreBranch>> fetchBranchesForStore(int storeId) async => getBranchesForStore(storeId);

  @override
  Future<Store?> fetchStoreById(int id) async => getStoreById(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBranchesCityNotifier extends StateNotifier<CityState> implements CityNotifier {
  MockBranchesCityNotifier(List<City> initialCities)
      : super(CityState(cities: initialCities, selectedCity: null, isLoading: false));

  @override
  Future<void> fetchCities() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
