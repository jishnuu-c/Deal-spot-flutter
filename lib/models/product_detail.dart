import 'package:equatable/equatable.dart';

class ProductDetail extends Equatable {
  final int id;
  final int productId;
  final String attrKeyEn;
  final String attrKeyAr;
  final String attrValueEn;
  final String attrValueAr;
  final int sortOrder;

  const ProductDetail({
    required this.id,
    required this.productId,
    required this.attrKeyEn,
    required this.attrKeyAr,
    required this.attrValueEn,
    required this.attrValueAr,
    required this.sortOrder,
  });

  ProductDetail copyWith({
    int? id,
    int? productId,
    String? attrKeyEn,
    String? attrKeyAr,
    String? attrValueEn,
    String? attrValueAr,
    int? sortOrder,
  }) {
    return ProductDetail(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      attrKeyEn: attrKeyEn ?? this.attrKeyEn,
      attrKeyAr: attrKeyAr ?? this.attrKeyAr,
      attrValueEn: attrValueEn ?? this.attrValueEn,
      attrValueAr: attrValueAr ?? this.attrValueAr,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? (json['product_id'] as num?)?.toInt() ?? 0,
      attrKeyEn: json['attrKeyEn'] as String? ?? json['attr_key_en'] as String? ?? '',
      attrKeyAr: json['attrKeyAr'] as String? ?? json['attr_key_ar'] as String? ?? '',
      attrValueEn: json['attrValueEn'] as String? ?? json['attr_value_en'] as String? ?? '',
      attrValueAr: json['attrValueAr'] as String? ?? json['attr_value_ar'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'attr_key_en': attrKeyEn,
      'attr_key_ar': attrKeyAr,
      'attr_value_en': attrValueEn,
      'attr_value_ar': attrValueAr,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        attrKeyEn,
        attrKeyAr,
        attrValueEn,
        attrValueAr,
        sortOrder,
      ];
}
