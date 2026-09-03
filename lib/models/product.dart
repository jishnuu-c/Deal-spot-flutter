import 'package:equatable/equatable.dart';
import 'category.dart';
import 'product_detail.dart';
import 'product_image.dart';

class Product extends Equatable {
  final int id;
  final int categoryId;
  final String brand;
  final String brandAr;
  final String sku;
  final String barcode;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String primaryImageUrl;
  final String unit; // 'pcs' | 'kg' | 'g' | 'l' | 'ml' | 'pack' | 'box'
  final double unitSize;
  final int isActive;

  // Joins
  final Category? category;
  final List<ProductDetail>? details;
  final List<ProductImage>? images;

  const Product({
    required this.id,
    required this.categoryId,
    required this.brand,
    required this.brandAr,
    required this.sku,
    required this.barcode,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    required this.primaryImageUrl,
    required this.unit,
    required this.unitSize,
    required this.isActive,
    this.category,
    this.details,
    this.images,
  });

  Product copyWith({
    int? id,
    int? categoryId,
    String? brand,
    String? brandAr,
    String? sku,
    String? barcode,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? primaryImageUrl,
    String? unit,
    double? unitSize,
    int? isActive,
    Category? category,
    List<ProductDetail>? details,
    List<ProductImage>? images,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      brand: brand ?? this.brand,
      brandAr: brandAr ?? this.brandAr,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      unit: unit ?? this.unit,
      unitSize: unitSize ?? this.unitSize,
      isActive: isActive ?? this.isActive,
      category: category ?? this.category,
      details: details ?? this.details,
      images: images ?? this.images,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final isActiveVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1;

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryId'] as num?)?.toInt() ?? (json['category_id'] as num?)?.toInt() ?? 1,
      brand: json['brand'] as String? ?? json['brandNameEn'] as String? ?? '',
      brandAr: json['brandAr'] as String? ?? json['brand_ar'] as String? ?? json['brandNameAr'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? json['description_en'] as String?,
      descriptionAr: json['descriptionAr'] as String? ?? json['description_ar'] as String?,
      primaryImageUrl: json['primaryImageUrl'] as String? ?? json['primary_image_url'] as String? ?? '',
      unit: json['unit'] as String? ?? 'pcs',
      unitSize: (json['unitSize'] as num?)?.toDouble() ?? (json['unit_size'] as num?)?.toDouble() ?? 1.0,
      isActive: isActiveVal,
      category: json['category'] != null && json['category'] is Map ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      details: json['details'] != null && json['details'] is List
          ? (json['details'] as List).map((e) => ProductDetail.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      images: json['images'] != null && json['images'] is List
          ? (json['images'] as List).map((e) => ProductImage.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'brand': brand,
      'brand_ar': brandAr,
      'sku': sku,
      'barcode': barcode,
      'name_en': nameEn,
      'name_ar': nameAr,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'primary_image_url': primaryImageUrl,
      'unit': unit,
      'unit_size': unitSize,
      'is_active': isActive,
      if (category != null) 'category': category!.toJson(),
      if (details != null) 'details': details!.map((e) => e.toJson()).toList(),
      if (images != null) 'images': images!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        brand,
        brandAr,
        sku,
        barcode,
        nameEn,
        nameAr,
        descriptionEn,
        descriptionAr,
        primaryImageUrl,
        unit,
        unitSize,
        isActive,
        category,
        details,
        images,
      ];
}
