import 'package:equatable/equatable.dart';
import 'offer.dart';

class SavedOffer extends Equatable {
  final int id;
  final int userId;
  final int offerId;
  final String savedAt;
  
  // Joins
  final Offer? offer;

  const SavedOffer({
    required this.id,
    required this.userId,
    required this.offerId,
    required this.savedAt,
    this.offer,
  });

  SavedOffer copyWith({
    int? id,
    int? userId,
    int? offerId,
    String? savedAt,
    Offer? offer,
  }) {
    return SavedOffer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      offerId: offerId ?? this.offerId,
      savedAt: savedAt ?? this.savedAt,
      offer: offer ?? this.offer,
    );
  }

  factory SavedOffer.fromJson(Map<String, dynamic> json) {
    return SavedOffer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? (json['user_id'] as num?)?.toInt() ?? 0,
      offerId: (json['offerId'] as num?)?.toInt() ?? (json['offer_id'] as num?)?.toInt() ?? 0,
      savedAt: (json['savedAt'] ?? json['saved_at'] ?? '').toString(),
      offer: json['offer'] != null && json['offer'] is Map ? Offer.fromJson(json['offer'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'offer_id': offerId,
      'saved_at': savedAt,
      if (offer != null) 'offer': offer!.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, userId, offerId, savedAt, offer];
}
