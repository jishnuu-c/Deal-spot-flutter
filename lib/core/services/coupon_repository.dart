import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'offer_repository.dart';
import 'store_repository.dart';
import 'product_repository.dart';

class CouponNotifier extends StateNotifier<List<CouponCode>> {
  final Ref _ref;
  final ApiClient _apiClient;

  CouponNotifier(this._ref, this._apiClient) : super(const []) {
    fetchCoupons();
  }

  String get _couponBaseUrl => '${AppConfig.serverUrl}/api/coupons';

  Future<void> fetchCoupons() async {
    try {
      final response = await _apiClient.get('$_couponBaseUrl/fetch-all');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => CouponCode.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          state = list;
        }
      }
    } catch (_) {}
  }

  List<CouponCode> getCoupons({int? storeId, int? offerId}) {
    var list = state;
    if (storeId != null) {
      list = list.where((c) => c.storeId == storeId).toList();
    }
    if (offerId != null) {
      list = list.where((c) => c.offerId == offerId).toList();
    }
    return list.map((cc) => _populateCoupon(cc)).toList();
  }

  CouponCode _populateCoupon(CouponCode cc) {
    final offers = _ref.read(offerRepositoryProvider).offers;
    final stores = _ref.read(storeRepositoryProvider).stores;
    final products = _ref.read(productRepositoryProvider).products;

    Offer? offer;
    if (cc.offerId != null) {
      try {
        offer = offers.firstWhere((o) => o.id == cc.offerId);
      } catch (_) {}
    }

    Store? store;
    if (cc.storeId != null) {
      try {
        store = stores.firstWhere((s) => s.id == cc.storeId);
      } catch (_) {}
    }

    Product? product;
    if (cc.productId != null) {
      try {
        product = products.firstWhere((p) => p.id == cc.productId);
      } catch (_) {}
    }

    return cc.copyWith(
      offer: offer,
      store: store,
      product: product,
    );
  }

  // Admin CRUD
  Future<void> createCoupon(String code, String discountType, double value, double? minCart, String from, String until, int isActive, {int? offerId, int? storeId, int? productId, int? maxUses}) async {
    try {
      final response = await _apiClient.post(
        '$_couponBaseUrl/add-coupon',
        data: {
          'code': code,
          'discountType': discountType,
          'discountValue': value,
          'minCartValue': minCart,
          'validFrom': from,
          'validUntil': until,
          'active': isActive == 1,
          'offerId': offerId,
          'storeId': storeId,
          'productId': productId,
          'maxUses': maxUses,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final created = CouponCode.fromJson(response.data as Map<String, dynamic>);
        state = [...state, created];
        return;
      }
    } catch (_) {}

    final newId = state.isEmpty ? 1 : state.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final coupon = CouponCode(
      id: newId,
      code: code,
      discountType: discountType,
      discountValue: value,
      minCartValue: minCart,
      validFrom: from,
      validUntil: until,
      isActive: isActive,
      offerId: offerId,
      storeId: storeId,
      productId: productId,
      maxUses: maxUses,
      usedCount: 0,
    );
    state = [...state, coupon];
  }

  Future<void> updateCoupon(int id, String code, String discountType, double value, double? minCart, String from, String until, int isActive, {int? offerId, int? storeId, int? productId, int? maxUses}) async {
    try {
      await _apiClient.put(
        '$_couponBaseUrl/update/$id',
        data: {
          'code': code,
          'discountType': discountType,
          'discountValue': value,
          'minCartValue': minCart,
          'validFrom': from,
          'validUntil': until,
          'active': isActive == 1,
          'offerId': offerId,
          'storeId': storeId,
          'productId': productId,
          'maxUses': maxUses,
        },
      );
    } catch (_) {}

    state = state.map((c) {
      if (c.id == id) {
        return c.copyWith(
          code: code,
          discountType: discountType,
          discountValue: value,
          minCartValue: minCart,
          validFrom: from,
          validUntil: until,
          isActive: isActive,
          offerId: offerId,
          storeId: storeId,
          productId: productId,
          maxUses: maxUses,
        );
      }
      return c;
    }).toList();
  }

  Future<void> deleteCoupon(int id) async {
    try {
      await _apiClient.delete('$_couponBaseUrl/delete/$id');
    } catch (_) {}

    state = state.where((c) => c.id != id).toList();
  }
}

final couponRepositoryProvider = StateNotifierProvider<CouponNotifier, List<CouponCode>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CouponNotifier(ref, apiClient);
});
