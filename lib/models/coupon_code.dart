import 'package:equatable/equatable.dart';
import 'offer.dart';
import 'store.dart';
import 'product.dart';

class CouponCode extends Equatable {
  final int id;
  final int? offerId;
  final String? offerTitleEn;
  final String? offerTitleAr;
  final int? storeId;
  final String? storeNameEn;
  final String? storeNameAr;
  final int? productId;
  final String? productNameEn;
  final String? productNameAr;
  final String code;
  final int? maxUses;
  final int usedCount;
  final String discountType; // 'PERCENT' | 'FIXED_SAR' (also supports legacy 'PERCENTAGE' | 'FIXED')
  final double discountValue;
  final double? minCartValue;
  final String validFrom;
  final String validUntil;
  final int isActive;

  // Joins
  final Offer? offer;
  final Store? store;
  final Product? product;

  const CouponCode({
    required this.id,
    this.offerId,
    this.offerTitleEn,
    this.offerTitleAr,
    this.storeId,
    this.storeNameEn,
    this.storeNameAr,
    this.productId,
    this.productNameEn,
    this.productNameAr,
    required this.code,
    this.maxUses,
    required this.usedCount,
    required this.discountType,
    required this.discountValue,
    this.minCartValue,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    this.offer,
    this.store,
    this.product,
  });

  bool get active => isActive == 1;

  CouponCode copyWith({
    int? id,
    int? offerId,
    String? offerTitleEn,
    String? offerTitleAr,
    int? storeId,
    String? storeNameEn,
    String? storeNameAr,
    int? productId,
    String? productNameEn,
    String? productNameAr,
    String? code,
    int? maxUses,
    int? usedCount,
    String? discountType,
    double? discountValue,
    double? minCartValue,
    String? validFrom,
    String? validUntil,
    int? isActive,
    Offer? offer,
    Store? store,
    Product? product,
  }) {
    return CouponCode(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      offerTitleEn: offerTitleEn ?? this.offerTitleEn,
      offerTitleAr: offerTitleAr ?? this.offerTitleAr,
      storeId: storeId ?? this.storeId,
      storeNameEn: storeNameEn ?? this.storeNameEn,
      storeNameAr: storeNameAr ?? this.storeNameAr,
      productId: productId ?? this.productId,
      productNameEn: productNameEn ?? this.productNameEn,
      productNameAr: productNameAr ?? this.productNameAr,
      code: code ?? this.code,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minCartValue: minCartValue ?? this.minCartValue,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      offer: offer ?? this.offer,
      store: store ?? this.store,
      product: product ?? this.product,
    );
  }

  factory CouponCode.fromJson(Map<String, dynamic> json) {
    final isActiveVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1;

    var dType = (json['discountType'] ?? json['discount_type'] ?? 'PERCENT').toString();
    if (dType == 'PERCENTAGE') dType = 'PERCENT';
    if (dType == 'FIXED') dType = 'FIXED_SAR';

    return CouponCode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      offerId: (json['offerId'] as num?)?.toInt() ?? (json['offer_id'] as num?)?.toInt(),
      offerTitleEn: json['offerTitleEn'] as String? ?? (json['offer'] is Map ? json['offer']['titleEn'] as String? : null),
      offerTitleAr: json['offerTitleAr'] as String? ?? (json['offer'] is Map ? json['offer']['titleAr'] as String? : null),
      storeId: (json['storeId'] as num?)?.toInt() ?? (json['store_id'] as num?)?.toInt(),
      storeNameEn: json['storeNameEn'] as String? ?? (json['store'] is Map ? json['store']['nameEn'] as String? : null),
      storeNameAr: json['storeNameAr'] as String? ?? (json['store'] is Map ? json['store']['nameAr'] as String? : null),
      productId: (json['productId'] as num?)?.toInt() ?? (json['product_id'] as num?)?.toInt(),
      productNameEn: json['productNameEn'] as String? ?? (json['product'] is Map ? json['product']['nameEn'] as String? : null),
      productNameAr: json['productNameAr'] as String? ?? (json['product'] is Map ? json['product']['nameAr'] as String? : null),
      code: json['code'] as String? ?? '',
      maxUses: (json['maxUses'] as num?)?.toInt() ?? (json['max_uses'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt() ?? (json['used_count'] as num?)?.toInt() ?? 0,
      discountType: dType,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minCartValue: (json['minCartValue'] as num?)?.toDouble() ?? (json['min_cart_value'] as num?)?.toDouble(),
      validFrom: (json['validFrom'] ?? json['valid_from'] ?? '').toString(),
      validUntil: (json['validUntil'] ?? json['valid_until'] ?? '').toString(),
      isActive: isActiveVal,
      offer: json['offer'] != null && json['offer'] is Map ? Offer.fromJson(json['offer'] as Map<String, dynamic>) : null,
      store: json['store'] != null && json['store'] is Map ? Store.fromJson(json['store'] as Map<String, dynamic>) : null,
      product: json['product'] != null && json['product'] is Map ? Product.fromJson(json['product'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'offerTitleEn': offerTitleEn,
      'offerTitleAr': offerTitleAr,
      'store_id': storeId,
      'storeNameEn': storeNameEn,
      'storeNameAr': storeNameAr,
      'product_id': productId,
      'productNameEn': productNameEn,
      'productNameAr': productNameAr,
      'code': code,
      'max_uses': maxUses,
      'used_count': usedCount,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_cart_value': minCartValue,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'is_active': isActive,
      'active': isActive == 1,
      if (offer != null) 'offer': offer!.toJson(),
      if (store != null) 'store': store!.toJson(),
      if (product != null) 'product': product!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        offerId,
        offerTitleEn,
        offerTitleAr,
        storeId,
        storeNameEn,
        storeNameAr,
        productId,
        productNameEn,
        productNameAr,
        code,
        maxUses,
        usedCount,
        discountType,
        discountValue,
        minCartValue,
        validFrom,
        validUntil,
        isActive,
        offer,
        store,
        product,
      ];
}
