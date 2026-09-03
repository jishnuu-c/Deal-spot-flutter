import 'package:equatable/equatable.dart';

class OfferImage extends Equatable {
  final int id;
  final int offerId;
  final String imageUrl;
  final int sortOrder;

  const OfferImage({
    required this.id,
    required this.offerId,
    required this.imageUrl,
    required this.sortOrder,
  });

  OfferImage copyWith({
    int? id,
    int? offerId,
    String? imageUrl,
    int? sortOrder,
  }) {
    return OfferImage(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory OfferImage.fromJson(Map<String, dynamic> json) {
    return OfferImage(
      id: json['id'] as int,
      offerId: json['offer_id'] as int,
      imageUrl: json['image_url'] as String,
      sortOrder: json['sort_order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, offerId, imageUrl, sortOrder];
}
