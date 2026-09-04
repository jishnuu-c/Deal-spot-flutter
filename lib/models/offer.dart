import 'package:equatable/equatable.dart';
import 'store.dart';
import 'product.dart';
import 'category.dart';
import 'city.dart';
import 'offer_image.dart';

class Offer extends Equatable {
  final int id;
  final int storeId;
  final int? productId;
  final int categoryId;
  final int cityId;
  final String titleEn;
  final String titleAr;
  final double originalPrice;
  final double offerPrice;
  final double discountPct;
  final String badgeType; // 'BOGO' | 'PROMO' | 'FLASH' | 'FEATURED' | 'NONE' | 'PERCENT_OFF' | 'NEW' | 'CLEARANCE' | 'COUPON'
  final String validFrom;
  final String validUntil;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? termsEn;
  final String? termsAr;
  final int isFeatured;
  final int isFlash;
  final int isInStore;
  final int isOnline;
  final int isActive;
  final int viewCount;
  final int saveCount;

  // Joins
  final Store? store;
  final Product? product;
  final Category? category;
  final City? city;
  final List<OfferImage>? images;
  final bool? isSaved; // dynamic field for active user
  final String? imageUrl; // optional single image field

  const Offer({
    required this.id,
    required this.storeId,
    this.productId,
    required this.categoryId,
    required this.cityId,
    required this.titleEn,
    required this.titleAr,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPct,
    required this.badgeType,
    required this.validFrom,
    required this.validUntil,
    this.descriptionEn,
    this.descriptionAr,
    this.termsEn,
    this.termsAr,
    required this.isFeatured,
    required this.isFlash,
    this.isInStore = 1,
    this.isOnline = 0,
    required this.isActive,
    required this.viewCount,
    required this.saveCount,
    this.store,
    this.product,
    this.category,
    this.city,
    this.images,
    this.isSaved,
    this.imageUrl,
  });

  bool get isExpired {
    if (validUntil.isEmpty) return false;
    try {
      final dt = DateTime.parse(validUntil.split('T')[0]);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return dt.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  bool get isUpcoming {
    if (validFrom.isEmpty) return false;
    try {
      final dt = DateTime.parse(validFrom.split('T')[0]);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return dt.isAfter(today);
    } catch (_) {
      return false;
    }
  }

  String get status {
    if (isExpired) return 'EXPIRED';
    if (isUpcoming) return 'UPCOMING';
    if (isActive == 1) return 'ACTIVE';
    return 'DISABLED';
  }

  String get primaryImageUrl {
    if (images != null && images!.isNotEmpty && images!.first.imageUrl.isNotEmpty) {
      return images!.first.imageUrl;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    if (product != null && product!.primaryImageUrl.isNotEmpty) {
      return product!.primaryImageUrl;
    }
    return '';
  }

  Offer copyWith({
    int? id,
    int? storeId,
    int? productId,
    int? categoryId,
    int? cityId,
    String? titleEn,
    String? titleAr,
    double? originalPrice,
    double? offerPrice,
    double? discountPct,
    String? badgeType,
    String? validFrom,
    String? validUntil,
    String? descriptionEn,
    String? descriptionAr,
    String? termsEn,
    String? termsAr,
    int? isFeatured,
    int? isFlash,
    int? isInStore,
    int? isOnline,
    int? isActive,
    int? viewCount,
    int? saveCount,
    Store? store,
    Product? product,
    Category? category,
    City? city,
    List<OfferImage>? images,
    bool? isSaved,
    String? imageUrl,
  }) {
    return Offer(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      cityId: cityId ?? this.cityId,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      discountPct: discountPct ?? this.discountPct,
      badgeType: badgeType ?? this.badgeType,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      termsEn: termsEn ?? this.termsEn,
      termsAr: termsAr ?? this.termsAr,
      isFeatured: isFeatured ?? this.isFeatured,
      isFlash: isFlash ?? this.isFlash,
      isInStore: isInStore ?? this.isInStore,
      isOnline: isOnline ?? this.isOnline,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
      store: store ?? this.store,
      product: product ?? this.product,
      category: category ?? this.category,
      city: city ?? this.city,
      images: images ?? this.images,
      isSaved: isSaved ?? this.isSaved,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    // Determine store
    Store? storeObj;
    if (json['store'] != null && json['store'] is Map) {
      storeObj = Store.fromJson(json['store'] as Map<String, dynamic>);
    } else if (json['storeNameEn'] != null || json['store_name_en'] != null) {
      storeObj = Store(
        id: (json['storeId'] as num?)?.toInt() ?? (json['store_id'] as num?)?.toInt() ?? 0,
        cityId: (json['cityId'] as num?)?.toInt() ?? (json['city_id'] as num?)?.toInt() ?? 1,
        categoryId: (json['categoryId'] as num?)?.toInt() ?? (json['category_id'] as num?)?.toInt() ?? 1,
        nameEn: json['storeNameEn'] as String? ?? json['store_name_en'] as String? ?? '',
        nameAr: json['storeNameAr'] as String? ?? json['store_name_ar'] as String? ?? '',
        logoUrl: json['storeLogoUrl'] as String? ?? json['store_logo_url'] as String? ?? '',
        isVerified: (json['storeVerified'] == true || json['is_verified'] == 1 || json['storeVerified'] == 1) ? 1 : 0,
        isActive: 1,
      );
    }

    // Determine product
    Product? prodObj;
    if (json['product'] != null && json['product'] is Map) {
      prodObj = Product.fromJson(json['product'] as Map<String, dynamic>);
    } else if (json['productNameEn'] != null || json['product_name_en'] != null) {
      prodObj = Product(
        id: (json['productId'] as num?)?.toInt() ?? (json['product_id'] as num?)?.toInt() ?? 0,
        categoryId: (json['categoryId'] as num?)?.toInt() ?? (json['category_id'] as num?)?.toInt() ?? 0,
        brand: json['brandNameEn'] as String? ?? json['brand_name_en'] as String? ?? '',
        brandAr: json['brandNameAr'] as String? ?? json['brand_name_ar'] as String? ?? '',
        sku: '',
        barcode: '',
        nameEn: json['productNameEn'] as String? ?? json['product_name_en'] as String? ?? '',
        nameAr: json['productNameAr'] as String? ?? json['product_name_ar'] as String? ?? '',
        primaryImageUrl: json['productPrimaryImageUrl'] as String? ?? json['product_primary_image_url'] as String? ?? json['productImageUrl'] as String? ?? '',
        unit: 'piece',
        unitSize: 1,
        isActive: 1,
      );
    }

    // Determine category
    Category? catObj;
    if (json['category'] != null && json['category'] is Map) {
      catObj = Category.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['categoryNameEn'] != null || json['category_name_en'] != null) {
      catObj = Category(
        id: (json['categoryId'] as num?)?.toInt() ?? (json['category_id'] as num?)?.toInt() ?? 0,
        nameEn: json['categoryNameEn'] as String? ?? json['category_name_en'] as String? ?? '',
        nameAr: json['categoryNameAr'] as String? ?? json['category_name_ar'] as String? ?? '',
        iconSlug: 'local_offer',
        sortOrder: 1,
        isActive: 1,
      );
    }

    // Offer images
    List<OfferImage>? imgs;
    if (json['images'] != null && json['images'] is List) {
      imgs = (json['images'] as List).map((e) => OfferImage.fromJson(e as Map<String, dynamic>)).toList();
    } else if (json['imageUrl'] != null && (json['imageUrl'] as String).isNotEmpty) {
      imgs = [OfferImage(id: 1, offerId: (json['id'] as num?)?.toInt() ?? 0, imageUrl: json['imageUrl'] as String, sortOrder: 1)];
    }

    final isFeaturedVal = json['featured'] is bool
        ? ((json['featured'] as bool) ? 1 : 0)
        : (json['is_featured'] as num?)?.toInt() ?? (json['isFeatured'] as num?)?.toInt() ?? 0;

    final isFlashVal = json['flash'] is bool
        ? ((json['flash'] as bool) ? 1 : 0)
        : (json['is_flash'] as num?)?.toInt() ?? (json['isFlash'] as num?)?.toInt() ?? 0;

    final isInStoreVal = json['inStore'] is bool
        ? ((json['inStore'] as bool) ? 1 : 0)
        : (json['is_in_store'] as num?)?.toInt() ?? (json['isInStore'] as num?)?.toInt() ?? 1;

    final isOnlineVal = json['online'] is bool
        ? ((json['online'] as bool) ? 1 : 0)
        : (json['is_online'] as num?)?.toInt() ?? (json['isOnline'] as num?)?.toInt() ?? 0;

    final isActiveVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1;

    String? singleImg = json['imageUrl'] as String? ?? json['thumbnailUrl'] as String? ?? json['image_url'] as String?;

    return Offer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      storeId: (json['storeId'] as num?)?.toInt() ?? (json['store_id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? (json['product_id'] as num?)?.toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt() ?? (json['category_id'] as num?)?.toInt() ?? 0,
      cityId: (json['cityId'] as num?)?.toInt() ?? (json['city_id'] as num?)?.toInt() ?? 1,
      titleEn: json['titleEn'] as String? ?? json['title_en'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? json['title_ar'] as String? ?? '',
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? (json['original_price'] as num?)?.toDouble() ?? 0.0,
      offerPrice: (json['offerPrice'] as num?)?.toDouble() ?? (json['offer_price'] as num?)?.toDouble() ?? 0.0,
      discountPct: (json['discountPct'] as num?)?.toDouble() ?? (json['discount_pct'] as num?)?.toDouble() ?? 0.0,
      badgeType: (json['badgeType'] ?? json['badge_type'] ?? 'NONE').toString(),
      validFrom: (json['validFrom'] ?? json['valid_from'] ?? '').toString(),
      validUntil: (json['validUntil'] ?? json['valid_until'] ?? '').toString(),
      descriptionEn: json['descriptionEn'] as String? ?? json['description_en'] as String?,
      descriptionAr: json['descriptionAr'] as String? ?? json['description_ar'] as String?,
      termsEn: json['termsEn'] as String? ?? json['terms_en'] as String?,
      termsAr: json['termsAr'] as String? ?? json['terms_ar'] as String?,
      isFeatured: isFeaturedVal,
      isFlash: isFlashVal,
      isInStore: isInStoreVal,
      isOnline: isOnlineVal,
      isActive: isActiveVal,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? (json['view_count'] as num?)?.toInt() ?? 0,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? (json['save_count'] as num?)?.toInt() ?? 0,
      store: storeObj,
      product: prodObj,
      category: catObj,
      city: json['city'] != null && json['city'] is Map ? City.fromJson(json['city'] as Map<String, dynamic>) : null,
      images: imgs,
      isSaved: json['isSaved'] as bool? ?? json['saved'] as bool?,
      imageUrl: singleImg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'product_id': productId,
      'category_id': categoryId,
      'city_id': cityId,
      'title_en': titleEn,
      'title_ar': titleAr,
      'original_price': originalPrice,
      'offer_price': offerPrice,
      'discount_pct': discountPct,
      'badge_type': badgeType,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'terms_en': termsEn,
      'terms_ar': termsAr,
      'is_featured': isFeatured,
      'is_flash': isFlash,
      'is_in_store': isInStore,
      'is_online': isOnline,
      'is_active': isActive,
      'view_count': viewCount,
      'save_count': saveCount,
      if (store != null) 'store': store!.toJson(),
      if (product != null) 'product': product!.toJson(),
      if (category != null) 'category': category!.toJson(),
      if (city != null) 'city': city!.toJson(),
      if (images != null) 'images': images!.map((e) => e.toJson()).toList(),
      if (isSaved != null) 'isSaved': isSaved,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        storeId,
        productId,
        categoryId,
        cityId,
        titleEn,
        titleAr,
        originalPrice,
        offerPrice,
        discountPct,
        badgeType,
        validFrom,
        validUntil,
        descriptionEn,
        descriptionAr,
        termsEn,
        termsAr,
        isFeatured,
        isFlash,
        isInStore,
        isOnline,
        isActive,
        viewCount,
        saveCount,
        store,
        product,
        category,
        city,
        images,
        isSaved,
        imageUrl,
      ];
}
