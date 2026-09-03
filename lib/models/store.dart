import 'package:equatable/equatable.dart';
import 'city.dart';
import 'category.dart';

class Store extends Equatable {
  final int id;
  final int cityId;
  final int categoryId;
  final String nameEn;
  final String nameAr;
  final String logoUrl;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? vatNumber;
  final String? crNumber;
  final String? contactPhone;
  final String? contactEmail;
  final String? website;
  final int isVerified;
  final int isActive;
  final bool featured;

  // Joined/Display Metadata
  final City? city;
  final Category? category;
  final String? cityNameEn;
  final String? cityNameAr;
  final String? categoryNameEn;
  final String? categoryNameAr;
  final int? branchesCount;
  final int? followersCount;
  final bool? isFollowed;

  const Store({
    required this.id,
    required this.cityId,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.logoUrl,
    this.descriptionEn,
    this.descriptionAr,
    this.vatNumber,
    this.crNumber,
    this.contactPhone,
    this.contactEmail,
    this.website,
    required this.isVerified,
    required this.isActive,
    this.featured = false,
    this.city,
    this.category,
    this.cityNameEn,
    this.cityNameAr,
    this.categoryNameEn,
    this.categoryNameAr,
    this.branchesCount,
    this.followersCount,
    this.isFollowed,
  });

  bool get active => isActive == 1;
  bool get verified => isVerified == 1;

  Store copyWith({
    int? id,
    int? cityId,
    int? categoryId,
    String? nameEn,
    String? nameAr,
    String? logoUrl,
    String? descriptionEn,
    String? descriptionAr,
    String? vatNumber,
    String? crNumber,
    String? contactPhone,
    String? contactEmail,
    String? website,
    int? isVerified,
    int? isActive,
    bool? featured,
    City? city,
    Category? category,
    String? cityNameEn,
    String? cityNameAr,
    String? categoryNameEn,
    String? categoryNameAr,
    int? branchesCount,
    int? followersCount,
    bool? isFollowed,
  }) {
    return Store(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      categoryId: categoryId ?? this.categoryId,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      logoUrl: logoUrl ?? this.logoUrl,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      vatNumber: vatNumber ?? this.vatNumber,
      crNumber: crNumber ?? this.crNumber,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      website: website ?? this.website,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      featured: featured ?? this.featured,
      city: city ?? this.city,
      category: category ?? this.category,
      cityNameEn: cityNameEn ?? this.cityNameEn,
      cityNameAr: cityNameAr ?? this.cityNameAr,
      categoryNameEn: categoryNameEn ?? this.categoryNameEn,
      categoryNameAr: categoryNameAr ?? this.categoryNameAr,
      branchesCount: branchesCount ?? this.branchesCount,
      followersCount: followersCount ?? this.followersCount,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    final isVerifiedVal = json['isVerified'] is bool
        ? ((json['isVerified'] as bool) ? 1 : 0)
        : (json['is_verified'] is bool
            ? ((json['is_verified'] as bool) ? 1 : 0)
            : (json['is_verified'] as num?)?.toInt() ??
                (json['isVerified'] as num?)?.toInt() ??
                0);

    final isActiveVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['is_active'] is bool
            ? ((json['is_active'] as bool) ? 1 : 0)
            : (json['is_active'] as num?)?.toInt() ??
                (json['isActive'] as num?)?.toInt() ??
                1);

    final featuredVal = json['featured'] is bool
        ? (json['featured'] as bool)
        : (json['is_featured'] is bool
            ? (json['is_featured'] as bool)
            : ((json['featured'] as num?)?.toInt() == 1 ||
                (json['is_featured'] as num?)?.toInt() == 1));

    return Store(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cityId: (json['cityId'] as num?)?.toInt() ?? (json['city_id'] as num?)?.toInt() ?? 1,
      categoryId: (json['categoryId'] as num?)?.toInt() ?? (json['category_id'] as num?)?.toInt() ?? 1,
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String? ?? json['logo'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? json['description_en'] as String?,
      descriptionAr: json['descriptionAr'] as String? ?? json['description_ar'] as String?,
      vatNumber: json['vatNumber'] as String? ?? json['vat_number'] as String?,
      crNumber: json['crNumber'] as String? ?? json['cr_number'] as String?,
      contactPhone: json['contactPhone'] as String? ?? json['contact_phone'] as String?,
      contactEmail: json['contactEmail'] as String? ?? json['contact_email'] as String?,
      website: json['website'] as String?,
      isVerified: isVerifiedVal,
      isActive: isActiveVal,
      featured: featuredVal,
      city: json['city'] != null && json['city'] is Map ? City.fromJson(json['city'] as Map<String, dynamic>) : null,
      category: json['category'] != null && json['category'] is Map ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      cityNameEn: json['cityNameEn'] as String? ?? json['cityName'] as String?,
      cityNameAr: json['cityNameAr'] as String?,
      categoryNameEn: json['categoryNameEn'] as String? ?? json['categoryName'] as String?,
      categoryNameAr: json['categoryNameAr'] as String?,
      branchesCount: (json['branchesCount'] as num?)?.toInt() ?? (json['branches_count'] as num?)?.toInt(),
      followersCount: (json['followersCount'] as num?)?.toInt() ?? (json['followers_count'] as num?)?.toInt(),
      isFollowed: json['isFollowed'] as bool? ?? json['is_followed'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_id': cityId,
      'category_id': categoryId,
      'name_en': nameEn,
      'name_ar': nameAr,
      'logo_url': logoUrl,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'vat_number': vatNumber,
      'cr_number': crNumber,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'website': website,
      'is_verified': isVerified,
      'is_active': isActive,
      'featured': featured,
      if (city != null) 'city': city!.toJson(),
      if (category != null) 'category': category!.toJson(),
      if (cityNameEn != null) 'cityNameEn': cityNameEn,
      if (cityNameAr != null) 'cityNameAr': cityNameAr,
      if (categoryNameEn != null) 'categoryNameEn': categoryNameEn,
      if (categoryNameAr != null) 'categoryNameAr': categoryNameAr,
      if (branchesCount != null) 'branches_count': branchesCount,
      if (followersCount != null) 'followers_count': followersCount,
      if (isFollowed != null) 'is_followed': isFollowed,
    };
  }

  @override
  List<Object?> get props => [
        id,
        cityId,
        categoryId,
        nameEn,
        nameAr,
        logoUrl,
        descriptionEn,
        descriptionAr,
        vatNumber,
        crNumber,
        contactPhone,
        contactEmail,
        website,
        isVerified,
        isActive,
        featured,
        city,
        category,
        cityNameEn,
        cityNameAr,
        categoryNameEn,
        categoryNameAr,
        branchesCount,
        followersCount,
        isFollowed,
      ];
}
