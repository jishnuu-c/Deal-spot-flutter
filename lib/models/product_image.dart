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
    final isPrimaryVal = json['primary'] is bool
        ? ((json['primary'] as bool) ? 1 : 0)
        : (json['is_primary'] as num?)?.toInt() ?? (json['isPrimary'] as num?)?.toInt() ?? 0;

    return ProductImage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? (json['product_id'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      altTextEn: json['altTextEn'] as String? ?? json['alt_text_en'] as String?,
      altTextAr: json['altTextAr'] as String? ?? json['alt_text_ar'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['sort_order'] as num?)?.toInt() ?? 0,
      isPrimary: isPrimaryVal,
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
  List<Object?> get props => [
        id,
        productId,
        imageUrl,
        altTextEn,
        altTextAr,
        sortOrder,
        isPrimary,
      ];
}
