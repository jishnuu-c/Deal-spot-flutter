import 'package:equatable/equatable.dart';

class FlyerPage extends Equatable {
  final int id;
  final int flyerId;
  final int pageNumber;
  final String imageUrl;
  final String thumbUrl;

  const FlyerPage({
    required this.id,
    required this.flyerId,
    required this.pageNumber,
    required this.imageUrl,
    required this.thumbUrl,
  });

  FlyerPage copyWith({
    int? id,
    int? flyerId,
    int? pageNumber,
    String? imageUrl,
    String? thumbUrl,
  }) {
    return FlyerPage(
      id: id ?? this.id,
      flyerId: flyerId ?? this.flyerId,
      pageNumber: pageNumber ?? this.pageNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
    );
  }

  factory FlyerPage.fromJson(Map<String, dynamic> json) {
    return FlyerPage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      flyerId: (json['flyerId'] as num?)?.toInt() ?? (json['flyer_id'] as num?)?.toInt() ?? 0,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? (json['page_number'] as num?)?.toInt() ?? 1,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      thumbUrl: json['thumbUrl'] as String? ?? json['thumb_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flyer_id': flyerId,
      'page_number': pageNumber,
      'image_url': imageUrl,
      'thumb_url': thumbUrl,
    };
  }

  @override
  List<Object?> get props => [id, flyerId, pageNumber, imageUrl, thumbUrl];
}
