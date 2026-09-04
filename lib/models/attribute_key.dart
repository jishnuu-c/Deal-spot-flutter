import 'package:equatable/equatable.dart';

class AttributeKey extends Equatable {
  final int id;
  final String attrKeyEn;
  final String attrKeyAr;

  const AttributeKey({
    required this.id,
    required this.attrKeyEn,
    required this.attrKeyAr,
  });

  factory AttributeKey.fromJson(Map<String, dynamic> json) {
    return AttributeKey(
      id: (json['id'] as num?)?.toInt() ?? 0,
      attrKeyEn: json['attrKeyEn'] as String? ?? json['attr_key_en'] as String? ?? '',
      attrKeyAr: json['attrKeyAr'] as String? ?? json['attr_key_ar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attr_key_en': attrKeyEn,
      'attr_key_ar': attrKeyAr,
    };
  }

  @override
  List<Object?> get props => [id, attrKeyEn, attrKeyAr];
}
