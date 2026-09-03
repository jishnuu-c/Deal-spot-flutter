import 'package:equatable/equatable.dart';

class ProductImage extends Equatable {
  final int id;
  final int productId;
  final String imageUrl;
  final String? altTextEn;
  final String? altTextAr;
  final int sortOrder;
  final int isPrimary;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.altTextEn,
    this.altTextAr,
    required this.sortOrder,
    required this.isPrimary,
  });

  ProductImage copyWith({
    int? id,
    int? productId,
    String? imageUrl,
    String? altTextEn,
    String? altTextAr,
    int? sortOrder,
    int? isPrimary,
  }) {
    return ProductImage(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      imageUrl: imageUrl ?? this.imageUrl,
      altTextEn: altTextEn ?? this.altTextEn,
      altTextAr: altTextAr ?? this.altTextAr,
      sortOrder: sortOrder ?? this.sortOrder,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      imageUrl: json['image_url'] as String,
      altTextEn: json['alt_text_en'] as String?,
      altTextAr: json['alt_text_ar'] as String?,
      sortOrder: json['sort_order'] as int,
      isPrimary: json['is_primary'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_url': imageUrl,
      'alt_text_en': altTextEn,
      'alt_text_ar': altTextAr,
      'sort_order': sortOrder,
      'is_primary': isPrimary,
    };
  }

  @override
  List<Object?> get props => [id, productId, imageUrl, altTextEn, altTextAr, sortOrder, isPrimary];
}
