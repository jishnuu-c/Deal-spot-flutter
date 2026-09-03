import 'package:equatable/equatable.dart';

class AuditLog extends Equatable {
  final int id;
  final String entityType;
  final int entityId;
  final String action;
  final int performedBy;
  final String? ipAddress;
  final Map<String, dynamic>? payload;
  final String createdAt;

  const AuditLog({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.performedBy,
    this.ipAddress,
    this.payload,
    required this.createdAt,
  });

  AuditLog copyWith({
    int? id,
    String? entityType,
    int? entityId,
    String? action,
    int? performedBy,
    String? ipAddress,
    Map<String, dynamic>? payload,
    String? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      performedBy: performedBy ?? this.performedBy,
      ipAddress: ipAddress ?? this.ipAddress,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as int,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int,
      action: json['action'] as String,
      performedBy: json['performed_by'] as int,
      ipAddress: json['ip_address'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'performed_by': performedBy,
      'ip_address': ipAddress,
      'payload': payload,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, entityType, entityId, action, performedBy, ipAddress, payload, createdAt];
}
