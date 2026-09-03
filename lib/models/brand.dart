import 'package:equatable/equatable.dart';
import 'category.dart';

class Brand extends Equatable {
  final int id;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? logoUrl;
  final String? bannerUrl;
  final String? websiteUrl;
  final bool featured;
  final bool active;
  final List<Category> categories;

  const Brand({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.logoUrl,
    this.bannerUrl,
    this.websiteUrl,
    this.featured = false,
    this.active = true,
    this.categories = const [],
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    var catList = <Category>[];
    if (json['categories'] != null && json['categories'] is List) {
      catList = (json['categories'] as List)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return Brand(
      id: json['id'] as int? ?? 0,
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? json['description_en'] as String?,
      descriptionAr: json['descriptionAr'] as String? ?? json['description_ar'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String?,
      bannerUrl: json['bannerUrl'] as String? ?? json['banner_url'] as String?,
      websiteUrl: json['websiteUrl'] as String? ?? json['website_url'] as String?,
      featured: json['featured'] as bool? ?? (json['is_featured'] == 1),
      active: json['active'] as bool? ?? (json['is_active'] != 0),
      categories: catList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'websiteUrl': websiteUrl,
      'featured': featured,
      'active': active,
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }

  Brand copyWith({
    int? id,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? logoUrl,
    String? bannerUrl,
    String? websiteUrl,
    bool? featured,
    bool? active,
    List<Category>? categories,
  }) {
    return Brand(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      featured: featured ?? this.featured,
      active: active ?? this.active,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nameEn,
        nameAr,
        descriptionEn,
        descriptionAr,
        logoUrl,
        bannerUrl,
        websiteUrl,
        featured,
        active,
        categories,
      ];
}
