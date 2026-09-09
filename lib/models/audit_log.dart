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
      id: (json['id'] as num?)?.toInt() ?? 0,
      entityType: (json['entityType'] ?? json['entity_type'] ?? '').toString(),
      entityId: (json['entityId'] as num?)?.toInt() ?? (json['entity_id'] as num?)?.toInt() ?? 0,
      action: (json['action'] ?? '').toString(),
      performedBy: (json['performedBy'] as num?)?.toInt() ?? (json['performed_by'] as num?)?.toInt() ?? 0,
      ipAddress: json['ipAddress'] as String? ?? json['ip_address'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '').toString(),
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
