import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/coupons_crud_screen.dart';
import 'package:dealspot_flutter/core/services/coupon_repository.dart';
import 'package:dealspot_flutter/core/services/store_repository.dart';
import 'package:dealspot_flutter/core/services/offer_repository.dart';
import 'package:dealspot_flutter/core/services/product_repository.dart';
import 'package:dealspot_flutter/core/widgets/custom_select_widget.dart';
import 'package:dealspot_flutter/models/models.dart';

void main() {
  final testStore = Store(
    id: 1,
    nameEn: 'Panda Hypermarket',
    nameAr: 'هايبر بنده',
    cityId: 1,
    categoryId: 1,
    logoUrl: '',
    isActive: 1,
    isVerified: 1,
  );

  final testOffer = Offer(
    id: 1,
    storeId: 1,
    categoryId: 1,
    cityId: 1,
    titleEn: 'Super Summer Discount',
    titleAr: 'عروض الصيف الكبرى',
    originalPrice: 100.0,
    offerPrice: 80.0,
    discountPct: 20.0,
    badgeType: 'PROMO',
    descriptionEn: 'Save up to 50%',
    descriptionAr: 'وفر حتى 50%',
    validFrom: '2026-06-01',
    validUntil: '2026-09-30',
    isActive: 1,
    isFeatured: 0,
    isFlash: 0,
    viewCount: 0,
    saveCount: 0,
  );

  const testCoupon = CouponCode(
    id: 10,
    storeId: 1,
    storeNameEn: 'Panda Hypermarket',
    storeNameAr: 'هايبر بنده',
    offerId: 1,
    offerTitleEn: 'Super Summer Discount',
    offerTitleAr: 'عروض الصيف الكبرى',
    code: 'EXTRA20',
    maxUses: 100,
    usedCount: 15,
    discountType: 'PERCENT',
    discountValue: 20.0,
    minCartValue: 50.0,
    validFrom: '2026-07-01',
    validUntil: '2026-09-30',
    isActive: 1,
  );

  testWidgets('CouponsCrudScreen renders table, filter toolbar, and opens Add modal', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          couponRepositoryProvider.overrideWith((ref) => MockCouponNotifier([testCoupon])),
          storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier([testStore])),
          offerRepositoryProvider.overrideWith((ref) => MockOfferNotifier([testOffer])),
          productRepositoryProvider.overrideWith((ref) => MockProductNotifier([])),
        ],
        child: const MaterialApp(
          home: CouponsCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Manage Promo Coupons'), findsOneWidget);
    expect(find.text('Add Coupon'), findsOneWidget);

    // Verify Table Row Data
    expect(find.text('EXTRA20'), findsOneWidget);
    expect(find.text('Panda Hypermarket'), findsWidgets);
    expect(find.text('20%'), findsOneWidget);

    // Tap Add Coupon button
    await tester.tap(find.text('Add Coupon'));
    await tester.pumpAndSettle();

    // Verify Modal Dialog Opened
    expect(find.text('Create New Promo Coupon'), findsOneWidget);
    expect(find.text('Coupon Code (UPPERCASE) *'), findsOneWidget);
    expect(find.byType(AppCustomSelect<int>), findsOneWidget);
    expect(find.text('Create Coupon'), findsOneWidget);
  });

  testWidgets('CouponsCrudScreen renders cleanly on narrow mobile screen width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          couponRepositoryProvider.overrideWith((ref) => MockCouponNotifier([testCoupon])),
          storeRepositoryProvider.overrideWith((ref) => MockStoreNotifier([testStore])),
          offerRepositoryProvider.overrideWith((ref) => MockOfferNotifier([testOffer])),
          productRepositoryProvider.overrideWith((ref) => MockProductNotifier([])),
        ],
        child: const MaterialApp(
          home: CouponsCrudScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Mobile Elements
    expect(find.text('Manage Promo Coupons'), findsOneWidget);
    expect(find.text('EXTRA20'), findsOneWidget);
    expect(find.text('Add Coupon'), findsOneWidget);

    // Tap Add Coupon button on mobile
    await tester.tap(find.text('Add Coupon'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Promo Coupon'), findsOneWidget);
  });
}

class MockCouponNotifier extends StateNotifier<List<CouponCode>> implements CouponNotifier {
  MockCouponNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> fetchCoupons({int? storeId}) async {}
}

class MockStoreNotifier extends StateNotifier<StoreState> implements StoreNotifier {
  MockStoreNotifier(List<Store> stores) : super(StoreState(stores: stores, branches: const [], followedStoreIds: const [], isLoading: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> fetchStores() async {}
}

class MockOfferNotifier extends StateNotifier<OfferState> implements OfferNotifier {
  MockOfferNotifier(List<Offer> offers) : super(OfferState(offers: offers, savedOfferIds: const [], images: const [], isLoading: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> fetchOffers({int? storeId, int? cityId, bool? includeExpired}) async {}
}

class MockProductNotifier extends StateNotifier<ProductState> implements ProductNotifier {
  MockProductNotifier(List<Product> products) : super(ProductState(products: products, details: const [], images: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> fetchProducts() async {}
}
