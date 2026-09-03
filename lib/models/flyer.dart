import 'package:equatable/equatable.dart';
import 'store.dart';
import 'city.dart';
import 'flyer_page.dart';

class Flyer extends Equatable {
  final int id;
  final int storeId;
  final int cityId;
  final String titleEn;
  final String titleAr;
  final String coverImageUrl;
  final String? pdfUrl;
  final int totalPages;
  final String validFrom;
  final String validUntil;
  final int isActive;
  final int viewCount;

  // Joins
  final Store? store;
  final City? city;
  final List<FlyerPage>? pages;

  const Flyer({
    required this.id,
    required this.storeId,
    required this.cityId,
    required this.titleEn,
    required this.titleAr,
    required this.coverImageUrl,
    this.pdfUrl,
    required this.totalPages,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    required this.viewCount,
    this.store,
    this.city,
    this.pages,
  });

  Flyer copyWith({
    int? id,
    int? storeId,
    int? cityId,
    String? titleEn,
    String? titleAr,
    String? coverImageUrl,
    String? pdfUrl,
    int? totalPages,
    String? validFrom,
    String? validUntil,
    int? isActive,
    int? viewCount,
    Store? store,
    City? city,
    List<FlyerPage>? pages,
  }) {
    return Flyer(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      cityId: cityId ?? this.cityId,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      totalPages: totalPages ?? this.totalPages,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      store: store ?? this.store,
      city: city ?? this.city,
      pages: pages ?? this.pages,
    );
  }

  factory Flyer.fromJson(Map<String, dynamic> json) {
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

    final isActiveVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1;

    return Flyer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      storeId: (json['storeId'] as num?)?.toInt() ?? (json['store_id'] as num?)?.toInt() ?? 0,
      cityId: (json['cityId'] as num?)?.toInt() ?? (json['city_id'] as num?)?.toInt() ?? 1,
      titleEn: json['titleEn'] as String? ?? json['title_en'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? json['title_ar'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? json['cover_image_url'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String? ?? json['pdf_url'] as String?,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? (json['total_pages'] as num?)?.toInt() ?? 0,
      validFrom: (json['validFrom'] ?? json['valid_from'] ?? '').toString(),
      validUntil: (json['validUntil'] ?? json['valid_until'] ?? '').toString(),
      isActive: isActiveVal,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? (json['view_count'] as num?)?.toInt() ?? 0,
      store: storeObj,
      city: json['city'] != null && json['city'] is Map ? City.fromJson(json['city'] as Map<String, dynamic>) : null,
      pages: json['pages'] != null && json['pages'] is List
          ? (json['pages'] as List).map((e) => FlyerPage.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'city_id': cityId,
      'title_en': titleEn,
      'title_ar': titleAr,
      'cover_image_url': coverImageUrl,
      'pdf_url': pdfUrl,
      'total_pages': totalPages,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'is_active': isActive,
      'view_count': viewCount,
      if (store != null) 'store': store!.toJson(),
      if (city != null) 'city': city!.toJson(),
      if (pages != null) 'pages': pages!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        storeId,
        cityId,
        titleEn,
        titleAr,
        coverImageUrl,
        pdfUrl,
        totalPages,
        validFrom,
        validUntil,
        isActive,
        viewCount,
        store,
        city,
        pages,
      ];
}
