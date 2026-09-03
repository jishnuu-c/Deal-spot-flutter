import 'package:equatable/equatable.dart';
import 'store.dart';

class StoreFollow extends Equatable {
  final int id;
  final int userId;
  final int storeId;
  final String followedAt;
  
  // Joins
  final Store? store;

  const StoreFollow({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.followedAt,
    this.store,
  });

  StoreFollow copyWith({
    int? id,
    int? userId,
    int? storeId,
    String? followedAt,
    Store? store,
  }) {
    return StoreFollow(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      followedAt: followedAt ?? this.followedAt,
      store: store ?? this.store,
    );
  }

  factory StoreFollow.fromJson(Map<String, dynamic> json) {
    return StoreFollow(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      storeId: json['store_id'] as int,
      followedAt: json['followed_at'] as String,
      store: json['store'] != null ? Store.fromJson(json['store'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store_id': storeId,
      'followed_at': followedAt,
      if (store != null) 'store': store!.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, userId, storeId, followedAt, store];
}
