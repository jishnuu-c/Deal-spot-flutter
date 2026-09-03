import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int id;
  final int? parentId;
  final String nameEn;
  final String nameAr;
  final String iconSlug;
  final String? imageUrl;
  final int sortOrder;
  final int isActive;

  const Category({
    required this.id,
    this.parentId,
    required this.nameEn,
    required this.nameAr,
    required this.iconSlug,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
  });

  Category copyWith({
    int? id,
    int? parentId,
    String? nameEn,
    String? nameAr,
    String? iconSlug,
    String? imageUrl,
    int? sortOrder,
    int? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      iconSlug: iconSlug ?? this.iconSlug,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final isActiveVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['isActive'] is bool
            ? ((json['isActive'] as bool) ? 1 : 0)
            : (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1);

    return Category(
      id: (json['id'] as num?)?.toInt() ?? 0,
      parentId: (json['parentId'] as num?)?.toInt() ?? (json['parent_id'] as num?)?.toInt(),
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      iconSlug: json['iconSlug'] as String? ?? json['icon_slug'] as String? ?? 'local_offer',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['sort_order'] as num?)?.toInt() ?? 1,
      isActive: isActiveVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name_en': nameEn,
      'name_ar': nameAr,
      'icon_slug': iconSlug,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, parentId, nameEn, nameAr, iconSlug, imageUrl, sortOrder, isActive];
}
