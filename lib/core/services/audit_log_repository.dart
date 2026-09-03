import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';

class AuditLogNotifier extends StateNotifier<List<AuditLog>> {
  AuditLogNotifier() : super(const []);

  void logAction(String entityType, int entityId, String action, int performedBy, String? ipAddress, Map<String, dynamic>? payload) {
    final newId = state.isEmpty ? 1 : state.map((log) => log.id).reduce((a, b) => a > b ? a : b) + 1;
    final log = AuditLog(
      id: newId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      performedBy: performedBy,
      ipAddress: ipAddress,
      payload: payload,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = [log, ...state];
  }
}

final auditLogRepositoryProvider = StateNotifierProvider<AuditLogNotifier, List<AuditLog>>((ref) {
  return AuditLogNotifier();
});
