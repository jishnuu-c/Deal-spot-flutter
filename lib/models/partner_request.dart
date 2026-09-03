import 'package:equatable/equatable.dart';

enum PartnerRequestStatus { PENDING, APPROVED, REJECTED }

class PartnerRequest extends Equatable {
  final int id;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String storeNameEn;
  final String storeNameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final int? cityId;
  final String? cityNameEn;
  final String? cityNameAr;
  final int? categoryId;
  final String? categoryNameEn;
  final String? categoryNameAr;
  final String? crNumber;
  final String? vatNumber;
  final String? website;
  final String? logoUrl;
  final String? bannerUrl;
  final String? contactAddress;
  final PartnerRequestStatus status;
  final String? rejectionReason;
  final int? createdStoreId;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const PartnerRequest({
    required this.id,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.storeNameEn,
    required this.storeNameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.cityId,
    this.cityNameEn,
    this.cityNameAr,
    this.categoryId,
    this.categoryNameEn,
    this.categoryNameAr,
    this.crNumber,
    this.vatNumber,
    this.website,
    this.logoUrl,
    this.bannerUrl,
    this.contactAddress,
    this.status = PartnerRequestStatus.PENDING,
    this.rejectionReason,
    this.createdStoreId,
    this.reviewedAt,
    this.createdAt,
  });

  factory PartnerRequest.fromJson(Map<String, dynamic> json) {
    PartnerRequestStatus parseStatus(String? s) {
      if (s == 'APPROVED') return PartnerRequestStatus.APPROVED;
      if (s == 'REJECTED') return PartnerRequestStatus.REJECTED;
      return PartnerRequestStatus.PENDING;
    }

    return PartnerRequest(
      id: json['id'] as int? ?? 0,
      applicantName: json['applicantName'] as String? ?? '',
      applicantEmail: json['applicantEmail'] as String? ?? '',
      applicantPhone: json['applicantPhone'] as String? ?? '',
      storeNameEn: json['storeNameEn'] as String? ?? '',
      storeNameAr: json['storeNameAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      cityId: json['cityId'] as int?,
      cityNameEn: json['cityNameEn'] as String?,
      cityNameAr: json['cityNameAr'] as String?,
      categoryId: json['categoryId'] as int?,
      categoryNameEn: json['categoryNameEn'] as String?,
      categoryNameAr: json['categoryNameAr'] as String?,
      crNumber: json['crNumber'] as String?,
      vatNumber: json['vatNumber'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      contactAddress: json['contactAddress'] as String?,
      status: parseStatus(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdStoreId: json['createdStoreId'] as int?,
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'storeNameEn': storeNameEn,
      'storeNameAr': storeNameAr,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'cityId': cityId,
      'cityNameEn': cityNameEn,
      'cityNameAr': cityNameAr,
      'categoryId': categoryId,
      'categoryNameEn': categoryNameEn,
      'categoryNameAr': categoryNameAr,
      'crNumber': crNumber,
      'vatNumber': vatNumber,
      'website': website,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'contactAddress': contactAddress,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdStoreId': createdStoreId,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  PartnerRequest copyWith({
    int? id,
    String? applicantName,
    String? applicantEmail,
    String? applicantPhone,
    String? storeNameEn,
    String? storeNameAr,
    String? descriptionEn,
    String? descriptionAr,
    int? cityId,
    String? cityNameEn,
    String? cityNameAr,
    int? categoryId,
    String? categoryNameEn,
    String? categoryNameAr,
    String? crNumber,
    String? vatNumber,
    String? website,
    String? logoUrl,
    String? bannerUrl,
    String? contactAddress,
    PartnerRequestStatus? status,
    String? rejectionReason,
    int? createdStoreId,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return PartnerRequest(
      id: id ?? this.id,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      storeNameEn: storeNameEn ?? this.storeNameEn,
      storeNameAr: storeNameAr ?? this.storeNameAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      cityId: cityId ?? this.cityId,
      cityNameEn: cityNameEn ?? this.cityNameEn,
      cityNameAr: cityNameAr ?? this.cityNameAr,
      categoryId: categoryId ?? this.categoryId,
      categoryNameEn: categoryNameEn ?? this.categoryNameEn,
      categoryNameAr: categoryNameAr ?? this.categoryNameAr,
      crNumber: crNumber ?? this.crNumber,
      vatNumber: vatNumber ?? this.vatNumber,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      contactAddress: contactAddress ?? this.contactAddress,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdStoreId: createdStoreId ?? this.createdStoreId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        applicantName,
        applicantEmail,
        applicantPhone,
        storeNameEn,
        storeNameAr,
        status,
        createdAt,
      ];
}
