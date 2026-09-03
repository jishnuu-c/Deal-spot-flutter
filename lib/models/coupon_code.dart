import 'package:equatable/equatable.dart';
import 'offer.dart';
import 'store.dart';
import 'product.dart';

class CouponCode extends Equatable {
  final int id;
  final int? offerId;
  final int? storeId;
  final int? productId;
  final String code;
  final int? maxUses;
  final int usedCount;
  final String discountType; // 'PERCENTAGE' | 'FIXED' | 'FREE_SHIPPING'
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
    this.storeId,
    this.productId,
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

  CouponCode copyWith({
    int? id,
    int? offerId,
    int? storeId,
    int? productId,
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
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
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

    return CouponCode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      offerId: (json['offerId'] as num?)?.toInt() ?? (json['offer_id'] as num?)?.toInt(),
      storeId: (json['storeId'] as num?)?.toInt() ?? (json['store_id'] as num?)?.toInt(),
      productId: (json['productId'] as num?)?.toInt() ?? (json['product_id'] as num?)?.toInt(),
      code: json['code'] as String? ?? '',
      maxUses: (json['maxUses'] as num?)?.toInt() ?? (json['max_uses'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt() ?? (json['used_count'] as num?)?.toInt() ?? 0,
      discountType: (json['discountType'] ?? json['discount_type'] ?? 'PERCENTAGE').toString(),
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
      'store_id': storeId,
      'product_id': productId,
      'code': code,
      'max_uses': maxUses,
      'used_count': usedCount,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_cart_value': minCartValue,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'is_active': isActive,
      if (offer != null) 'offer': offer!.toJson(),
      if (store != null) 'store': store!.toJson(),
      if (product != null) 'product': product!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        offerId,
        storeId,
        productId,
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
