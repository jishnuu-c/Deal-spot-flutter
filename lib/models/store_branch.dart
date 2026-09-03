import 'package:equatable/equatable.dart';
import 'store.dart';
import 'city.dart';

class StoreBranch extends Equatable {
  final int id;
  final int storeId;
  final int cityId;
  final String branchName;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final int isActive;
  final String? contactPhone;
  final String? addressLine;

  // Joins
  final Store? store;
  final City? city;

  const StoreBranch({
    required this.id,
    required this.storeId,
    required this.cityId,
    required this.branchName,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.isActive,
    this.contactPhone,
    this.addressLine,
    this.store,
    this.city,
  });

  bool get active => isActive == 1;
  String? get cityNameEn => city?.nameEn;
  String? get cityNameAr => city?.nameAr;

  StoreBranch copyWith({
    int? id,
    int? storeId,
    int? cityId,
    String? branchName,
    double? latitude,
    double? longitude,
    String? openTime,
    String? closeTime,
    int? isActive,
    String? contactPhone,
    String? addressLine,
    Store? store,
    City? city,
  }) {
    return StoreBranch(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      cityId: cityId ?? this.cityId,
      branchName: branchName ?? this.branchName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isActive: isActive ?? this.isActive,
      contactPhone: contactPhone ?? this.contactPhone,
      addressLine: addressLine ?? this.addressLine,
      store: store ?? this.store,
      city: city ?? this.city,
    );
  }

  factory StoreBranch.fromJson(Map<String, dynamic> json) {
    final activeVal = json['active'] is bool
        ? ((json['active'] as bool) ? 1 : 0)
        : (json['is_active'] as num?)?.toInt() ?? (json['isActive'] as num?)?.toInt() ?? 1;

    return StoreBranch(
      id: (json['id'] as num?)?.toInt() ?? 0,
      storeId: (json['store_id'] as num?)?.toInt() ?? (json['storeId'] as num?)?.toInt() ?? 0,
      cityId: (json['city_id'] as num?)?.toInt() ?? (json['cityId'] as num?)?.toInt() ?? 0,
      branchName: json['branch_name'] as String? ?? json['branchName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      openTime: json['open_time'] as String? ?? json['openTime'] as String? ?? '08:00:00',
      closeTime: json['close_time'] as String? ?? json['closeTime'] as String? ?? '22:00:00',
      isActive: activeVal,
      contactPhone: json['phone'] as String? ?? json['contact_phone'] as String? ?? json['contactPhone'] as String?,
      addressLine: json['addressEn'] as String? ?? json['address_line'] as String? ?? json['addressLine'] as String? ?? json['addressAr'] as String?,
      store: json['store'] != null ? Store.fromJson(json['store'] as Map<String, dynamic>) : null,
      city: json['city'] != null ? City.fromJson(json['city'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'city_id': cityId,
      'branch_name': branchName,
      'latitude': latitude,
      'longitude': longitude,
      'open_time': openTime,
      'close_time': closeTime,
      'is_active': isActive,
      'contact_phone': contactPhone,
      'address_line': addressLine,
      if (store != null) 'store': store!.toJson(),
      if (city != null) 'city': city!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        storeId,
        cityId,
        branchName,
        latitude,
        longitude,
        openTime,
        closeTime,
        isActive,
        contactPhone,
        addressLine,
        store,
        city,
      ];
}
