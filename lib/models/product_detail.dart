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
      id: json['id'] as int,
      productId: json['product_id'] as int,
      attrKeyEn: json['attr_key_en'] as String,
      attrKeyAr: json['attr_key_ar'] as String,
      attrValueEn: json['attr_value_en'] as String,
      attrValueAr: json['attr_value_ar'] as String,
      sortOrder: json['sort_order'] as int,
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
  List<Object?> get props => [id, productId, attrKeyEn, attrKeyAr, attrValueEn, attrValueAr, sortOrder];
}
