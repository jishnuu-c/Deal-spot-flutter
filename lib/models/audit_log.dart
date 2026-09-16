import 'package:equatable/equatable.dart';

int _parseInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val.trim()) ?? fallback;
  return fallback;
}

int? _parseNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val.trim());
  return null;
}

bool? _parseNullableBool(dynamic val) {
  if (val == null) return null;
  if (val is bool) return val;
  if (val is num) return val != 0;
  if (val is String) {
    final s = val.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  return null;
}

class AdminUserSummary extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;

  const AdminUserSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
  });

  factory AdminUserSummary.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      if (rawJson is String && rawJson.isNotEmpty) {
        return AdminUserSummary(
          id: 0,
          fullName: rawJson,
          email: '',
          role: '',
        );
      }
      return const AdminUserSummary(id: 0, fullName: '', email: '', role: '');
    }
    final json = Map<String, dynamic>.from(rawJson);
    return AdminUserSummary(
      id: _parseInt(json['id'] ?? json['userId'] ?? json['user_id']),
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'] ?? json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }

  @override
  List<Object?> get props => [id, fullName, email, role, phone];
}

class AuditLog extends Equatable {
  final int id;
  final String? requestId;
  final int? userId;
  final String entityType;
  final int entityId;
  final String action;
  final String? httpMethod;
  final String? endpoint;
  final int? statusCode;
  final bool? success;
  final String? ipAddress;
  final String? userAgent;
  final int? durationMs;
  final String? errorType;
  final String? errorMessage;
  final AdminUserSummary? performedBy;
  final int? performedById;
  final String? rawPayload;
  final Map<String, dynamic>? parsedPayload;
  final String createdAt;

  const AuditLog({
    required this.id,
    this.requestId,
    this.userId,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.httpMethod,
    this.endpoint,
    this.statusCode,
    this.success,
    this.ipAddress,
    this.userAgent,
    this.durationMs,
    this.errorType,
    this.errorMessage,
    this.performedBy,
    this.performedById,
    this.rawPayload,
    this.parsedPayload,
    required this.createdAt,
  });

  factory AuditLog.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return AuditLog(
        id: 0,
        entityType: '',
        entityId: 0,
        action: '',
        createdAt: '',
      );
    }
    final json = Map<String, dynamic>.from(rawJson);

    AdminUserSummary? user;
    int? userIdVal = _parseNullableInt(json['userId'] ?? json['user_id'] ?? json['performedById'] ?? json['performed_by_id']);

    if (json['performedBy'] is Map) {
      user = AdminUserSummary.fromJson(json['performedBy']);
      if (user.id > 0) userIdVal = user.id;
    } else if (json['performedBy'] is num) {
      userIdVal = _parseNullableInt(json['performedBy']);
    } else if (json['performed_by'] is num) {
      userIdVal = _parseNullableInt(json['performed_by']);
    } else if (json['performedBy'] is String && (json['performedBy'] as String).isNotEmpty) {
      user = AdminUserSummary(
        id: userIdVal ?? 0,
        fullName: json['performedBy'] as String,
        email: '',
        role: '',
      );
    }

    String? raw;
    Map<String, dynamic>? parsed;
    final p = json['payload'] ?? json['rawPayload'] ?? json['raw_payload'] ?? json['body'];
    if (p != null) {
      if (p is Map) {
        parsed = Map<String, dynamic>.from(p);
        raw = parsed.toString();
      } else if (p is String) {
        raw = p;
      }
    }

    final idVal = _parseInt(json['auditLogId'] ?? json['audit_log_id'] ?? json['id']);

    return AuditLog(
      id: idVal,
      requestId: (json['requestId'] ?? json['request_id'])?.toString(),
      userId: userIdVal,
      entityType: (json['entityType'] ?? json['entity_type'] ?? '').toString(),
      entityId: _parseInt(json['entityId'] ?? json['entity_id']),
      action: (json['action'] ?? '').toString(),
      httpMethod: (json['httpMethod'] ?? json['http_method'] ?? json['method'])?.toString(),
      endpoint: (json['endpoint'] ?? json['url'] ?? json['path'])?.toString(),
      statusCode: _parseNullableInt(json['statusCode'] ?? json['status_code'] ?? json['status']),
      success: _parseNullableBool(json['success']),
      ipAddress: (json['ipAddress'] ?? json['ip_address'] ?? json['ip'])?.toString(),
      userAgent: (json['userAgent'] ?? json['user_agent'])?.toString(),
      durationMs: _parseNullableInt(json['durationMs'] ?? json['duration_ms'] ?? json['duration']),
      errorType: (json['errorType'] ?? json['error_type'])?.toString(),
      errorMessage: (json['errorMessage'] ?? json['error_message'] ?? json['error'])?.toString(),
      performedBy: user,
      performedById: userIdVal,
      rawPayload: raw,
      parsedPayload: parsed,
      createdAt: (json['createdAt'] ?? json['created_at'] ?? json['timestamp'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auditLogId': id,
      'requestId': requestId,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'httpMethod': httpMethod,
      'endpoint': endpoint,
      'statusCode': statusCode,
      'success': success,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'durationMs': durationMs,
      'errorType': errorType,
      'errorMessage': errorMessage,
      'performedBy': performedBy?.toJson() ?? performedById,
      'payload': rawPayload ?? parsedPayload,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        requestId,
        userId,
        entityType,
        entityId,
        action,
        httpMethod,
        endpoint,
        statusCode,
        success,
        ipAddress,
        userAgent,
        durationMs,
        errorType,
        errorMessage,
        performedBy,
        performedById,
        rawPayload,
        parsedPayload,
        createdAt,
      ];
}

class RecentActivity extends Equatable {
  final int? auditLogId;
  final int? activityId;
  final String? title;
  final String? message;
  final String? description;
  final String? action;
  final String? entityType;
  final String? performedBy;
  final String? color;
  final String? createdAt;
  final String? timestamp;

  const RecentActivity({
    this.auditLogId,
    this.activityId,
    this.title,
    this.message,
    this.description,
    this.action,
    this.entityType,
    this.performedBy,
    this.color,
    this.createdAt,
    this.timestamp,
  });

  factory RecentActivity.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      return const RecentActivity();
    }
    final json = Map<String, dynamic>.from(rawJson);
    return RecentActivity(
      auditLogId: _parseNullableInt(json['auditLogId'] ?? json['audit_log_id']),
      activityId: _parseNullableInt(json['activityId'] ?? json['activity_id'] ?? json['id']),
      title: json['title']?.toString(),
      message: json['message']?.toString(),
      description: json['description']?.toString(),
      action: json['action']?.toString(),
      entityType: (json['entityType'] ?? json['entity_type'])?.toString(),
      performedBy: (json['performedBy'] is Map
          ? (json['performedBy']['fullName'] ?? json['performedBy']['name'])
          : json['performedBy'])?.toString(),
      color: json['color']?.toString(),
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
      timestamp: (json['timestamp'] ?? json['created_at'] ?? json['createdAt'])?.toString(),
    );
  }

  String get displayTitle => description ?? message ?? title ?? 'System Operation';
  String get displayTime => timestamp ?? createdAt ?? '';

  @override
  List<Object?> get props => [
        auditLogId,
        activityId,
        title,
        message,
        description,
        action,
        entityType,
        performedBy,
        color,
        createdAt,
        timestamp,
      ];
}

class AuditLogPage extends Equatable {
  final List<AuditLog> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  const AuditLogPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  factory AuditLogPage.fromJson(dynamic rawJson) {
    if (rawJson is! Map) {
      if (rawJson is List) {
        final list = rawJson
            .whereType<Map>()
            .map((e) => AuditLog.fromJson(e))
            .toList();
        return AuditLogPage(
          content: list,
          totalElements: list.length,
          totalPages: 1,
          size: list.length,
          number: 0,
        );
      }
      return const AuditLogPage(
        content: [],
        totalElements: 0,
        totalPages: 0,
        size: 20,
        number: 0,
      );
    }

    final json = Map<String, dynamic>.from(rawJson);
    final rawList = json['content'] ?? json['logs'] ?? json['items'] ?? json['records'] ?? json['data'];
    List<AuditLog> list = [];
    if (rawList is List) {
      list = rawList
          .whereType<Map>()
          .map((e) => AuditLog.fromJson(e))
          .toList();
    }

    final total = _parseInt(
      json['totalElements'] ??
          json['total_elements'] ??
          json['total'] ??
          json['totalCount'] ??
          json['total_count'],
      list.length,
    );

    final sizeVal = _parseInt(json['size'] ?? json['pageSize'] ?? json['page_size'], 20);
    final totalPages = _parseInt(
      json['totalPages'] ?? json['total_pages'],
      (total > 0 && sizeVal > 0) ? (total / sizeVal).ceil() : (list.isNotEmpty ? 1 : 0),
    );

    final number = _parseInt(json['number'] ?? json['page'] ?? json['pageNumber'] ?? json['page_number'], 0);

    return AuditLogPage(
      content: list,
      totalElements: total,
      totalPages: totalPages,
      size: sizeVal,
      number: number,
    );
  }

  @override
  List<Object?> get props => [content, totalElements, totalPages, size, number];
}

class AuditLogFilter extends Equatable {
  final String entityType;
  final String action;
  final int? performedById;
  final String? startDate;
  final String? endDate;
  final String searchKeyword;
  final int page;
  final int size;

  const AuditLogFilter({
    this.entityType = '',
    this.action = '',
    this.performedById,
    this.startDate,
    this.endDate,
    this.searchKeyword = '',
    this.page = 0,
    this.size = 20,
  });

  AuditLogFilter copyWith({
    String? entityType,
    String? action,
    int? performedById,
    String? startDate,
    String? endDate,
    String? searchKeyword,
    int? page,
    int? size,
  }) {
    return AuditLogFilter(
      entityType: entityType ?? this.entityType,
      action: action ?? this.action,
      performedById: performedById ?? this.performedById,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': '$page',
      'size': '$size',
    };
    if (entityType.trim().isNotEmpty) params['entityType'] = entityType.trim();
    if (action.trim().isNotEmpty) params['action'] = action.trim();
    if (performedById != null) params['performedById'] = '$performedById';
    if (startDate != null && startDate!.trim().isNotEmpty) {
      final s = startDate!.trim();
      params['startDate'] = s.contains('T') ? s : '${s}T00:00:00';
    }
    if (endDate != null && endDate!.trim().isNotEmpty) {
      final e = endDate!.trim();
      params['endDate'] = e.contains('T') ? e : '${e}T23:59:59';
    }
    if (searchKeyword.trim().isNotEmpty) params['searchKeyword'] = searchKeyword.trim();
    return params;
  }

  @override
  List<Object?> get props => [
        entityType,
        action,
        performedById,
        startDate,
        endDate,
        searchKeyword,
        page,
        size,
      ];
}
