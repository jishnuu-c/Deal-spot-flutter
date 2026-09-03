import 'package:equatable/equatable.dart';

class City extends Equatable {
  final int id;
  final String nameEn;
  final String nameAr;
  final String regionCode;
  final double latitude;
  final double longitude;
  final int isActive;

  const City({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.regionCode,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  City copyWith({
    int? id,
    String? nameEn,
    String? nameAr,
    String? regionCode,
    double? latitude,
    double? longitude,
    int? isActive,
  }) {
    return City(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      regionCode: regionCode ?? this.regionCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
    );
  }

  factory City.fromJson(Map<String, dynamic> json) {
    final isActiveVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['isActive'] is bool
            ? ((json['isActive'] as bool) ? 1 : 0)
            : (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1);

    return City(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nameEn: json['nameEn'] as String? ?? json['name_en'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? json['name_ar'] as String? ?? '',
      regionCode: json['regionCode'] as String? ?? json['region_code'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isActive: isActiveVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ar': nameAr,
      'region_code': regionCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, nameEn, nameAr, regionCode, latitude, longitude, isActive];
}
