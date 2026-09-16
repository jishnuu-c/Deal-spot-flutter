import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/services/audit_log_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedEntityType = '';
  String _selectedAction = '';
  String _startDate = '';
  String _endDate = '';
  int _pageSize = 20;

  static const List<Map<String, dynamic>> _entityTypes = [
    {'id': '', 'nameEn': 'All Entities', 'nameAr': 'جميع الكيانات', 'icon': Icons.category_rounded},
    {'id': 'OFFER', 'nameEn': 'Offer', 'nameAr': 'العروض (Offer)', 'icon': Icons.local_offer_rounded},
    {'id': 'PRODUCT', 'nameEn': 'Product', 'nameAr': 'المنتجات (Product)', 'icon': Icons.shopping_bag_rounded},
    {'id': 'BRAND', 'nameEn': 'Brand', 'nameAr': 'الماركات (Brand)', 'icon': Icons.loyalty_rounded},
    {'id': 'STORE', 'nameEn': 'Store', 'nameAr': 'المتاجر (Store)', 'icon': Icons.store_rounded},
    {'id': 'STORE_BRANCH', 'nameEn': 'Store Branch', 'nameAr': 'فروع المتاجر (Branch)', 'icon': Icons.storefront_rounded},
    {'id': 'CATEGORY', 'nameEn': 'Category', 'nameAr': 'الأقسام (Category)', 'icon': Icons.category_rounded},
    {'id': 'COUPON_CODE', 'nameEn': 'Coupon Code', 'nameAr': 'الكوبونات (Coupon)', 'icon': Icons.confirmation_number_rounded},
    {'id': 'FLYER', 'nameEn': 'Flyer', 'nameAr': 'المنشورات (Flyer)', 'icon': Icons.menu_book_rounded},
    {'id': 'PARTNER_REQUEST', 'nameEn': 'Partner Request', 'nameAr': 'طلبات الشراكة (Partner Req)', 'icon': Icons.handshake_rounded},
    {'id': 'ADMIN_USER', 'nameEn': 'Admin User', 'nameAr': 'المشرفين (Admin User)', 'icon': Icons.people_rounded},
    {'id': 'CITY', 'nameEn': 'City', 'nameAr': 'المدن (City)', 'icon': Icons.place_rounded},
    {'id': 'SAVED_OFFER', 'nameEn': 'Saved Offer', 'nameAr': 'العروض المحفوظة (Saved Offer)', 'icon': Icons.bookmark_rounded},
    {'id': 'STORE_FOLLOW', 'nameEn': 'Store Follow', 'nameAr': 'متابعة المتاجر (Store Follow)', 'icon': Icons.favorite_rounded},
    {'id': 'HTTP_REQUEST', 'nameEn': 'HTTP Request', 'nameAr': 'طلبات HTTP (HTTP Request)', 'icon': Icons.http_rounded},
  ];

  static const List<Map<String, dynamic>> _actions = [
    {'id': '', 'nameEn': 'All Actions', 'nameAr': 'جميع العمليات', 'icon': Icons.tune_rounded},
    {'id': 'CREATE', 'nameEn': 'CREATE', 'nameAr': 'إنشاء (CREATE)', 'icon': Icons.add_circle_outline_rounded},
    {'id': 'UPDATE', 'nameEn': 'UPDATE', 'nameAr': 'تحديث (UPDATE)', 'icon': Icons.edit_note_rounded},
    {'id': 'DELETE', 'nameEn': 'DELETE', 'nameAr': 'حذف (DELETE)', 'icon': Icons.delete_outline_rounded},
    {'id': 'APPROVE', 'nameEn': 'APPROVE', 'nameAr': 'موافقة (APPROVE)', 'icon': Icons.check_circle_outline_rounded},
    {'id': 'REJECT', 'nameEn': 'REJECT', 'nameAr': 'رفض (REJECT)', 'icon': Icons.cancel_outlined},
    {'id': 'BULK_EXPIRE', 'nameEn': 'BULK_EXPIRE', 'nameAr': 'إنهاء جماعي (BULK_EXPIRE)', 'icon': Icons.timer_off_outlined},
    {'id': 'LOGIN', 'nameEn': 'LOGIN', 'nameAr': 'تسجيل دخول (LOGIN)', 'icon': Icons.login_rounded},
    {'id': 'LOGOUT', 'nameEn': 'LOGOUT', 'nameAr': 'تسجيل خروج (LOGOUT)', 'icon': Icons.logout_rounded},
    {'id': 'SYSTEM_EVENT', 'nameEn': 'SYSTEM_EVENT', 'nameAr': 'حدث نظام (SYSTEM_EVENT)', 'icon': Icons.bolt_rounded},
  ];

  static const List<int> _pageSizeList = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLogs({int page = 0}) {
    final filter = AuditLogFilter(
      entityType: _selectedEntityType,
      action: _selectedAction,
      startDate: _startDate.isNotEmpty ? _startDate : null,
      endDate: _endDate.isNotEmpty ? _endDate : null,
      searchKeyword: _searchController.text.trim(),
      page: page,
      size: _pageSize,
    );
    ref.read(auditLogRepositoryProvider.notifier).fetchPagedLogs(filter: filter);
  }

  void _onFilterChange() {
    _loadLogs(page: 0);
  }

  void _resetFilters() {
    setState(() {
      _selectedEntityType = '';
      _selectedAction = '';
      _startDate = '';
      _endDate = '';
      _searchController.clear();
      _pageSize = 20;
    });
    _loadLogs(page: 0);
  }

  void _copyToClipboard(BuildContext context, String text, String label, bool isRtl) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(isRtl ? 'تم نسخ $label إلى الحافظة!' : '$label copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate.isNotEmpty ? DateTime.tryParse(_startDate) ?? now : now)
        : (_endDate.isNotEmpty ? DateTime.tryParse(_endDate) ?? now : now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isStart) {
          _startDate = formatted;
        } else {
          _endDate = formatted;
        }
      });
      _onFilterChange();
    }
  }

  Color _getActionColor(String? action, bool isDark) {
    if (action == null) return const Color(0xFF64748B);
    final act = action.toUpperCase();
    if (act.contains('CREATE') || act.contains('REGISTER')) return const Color(0xFF10B981);
    if (act.contains('UPDATE') || act.contains('EDIT')) return const Color(0xFF2563EB);
    if (act.contains('DELETE') || act.contains('REMOVE')) return const Color(0xFFEF4444);
    if (act.contains('APPROVE')) return const Color(0xFF0D9488);
    if (act.contains('REJECT')) return const Color(0xFFF59E0B);
    if (act.contains('LOGIN')) return const Color(0xFF06B6D4);
    if (act.contains('LOGOUT')) return const Color(0xFF64748B);
    if (act.contains('BULK')) return const Color(0xFF8B5CF6);
    return const Color(0xFF6366F1);
  }

  Color _getMethodColor(String? method) {
    switch ((method ?? '').toUpperCase()) {
      case 'GET': return const Color(0xFF10B981);
      case 'POST': return const Color(0xFF2563EB);
      case 'PUT': return const Color(0xFFF59E0B);
      case 'PATCH': return const Color(0xFF8B5CF6);
      case 'DELETE': return const Color(0xFFEF4444);
      default: return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(int? statusCode, bool? success) {
    if (statusCode != null) {
      if (statusCode >= 200 && statusCode < 300) return const Color(0xFF10B981);
      if (statusCode >= 300 && statusCode < 400) return const Color(0xFF06B6D4);
      if (statusCode >= 400 && statusCode < 500) return const Color(0xFFF59E0B);
      if (statusCode >= 500) return const Color(0xFFEF4444);
    }
    if (success == true) return const Color(0xFF10B981);
    if (success == false) return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }

  Color _getDurationColor(int? durationMs) {
    if (durationMs == null) return const Color(0xFF64748B);
    if (durationMs < 100) return const Color(0xFF10B981);
    if (durationMs < 500) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, y, h:mm:ss a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatPrettyJson(String? raw, Map<String, dynamic>? parsed) {
    if (parsed != null && parsed.isNotEmpty) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(parsed);
      } catch (_) {}
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(decoded);
      } catch (_) {
        return raw;
      }
    }
    return 'No payload data recorded for this operation.';
  }

  void _showInspectorModal(BuildContext context, AuditLog log, bool isRtl, bool isDark) {
    final hasError = log.errorMessage != null ||
        log.errorType != null ||
        (log.statusCode != null && log.statusCode! >= 400) ||
        log.success == false;

    final formattedJson = _formatPrettyJson(log.rawPayload, log.parsedPayload);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildActionPill(log.action, isDark),
                                _buildStatusBadge(log.statusCode, log.success, isDark),
                                if (log.durationMs != null) _buildLatencyBadge(log.durationMs!, isDark),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.manage_search_rounded, color: Color(0xFF2563EB), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  isRtl ? 'تفاصيل سجل العملية' : 'Audit Log Record Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(log.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Modal Body (Scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Alert Banner
                        if (hasError) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.errorType ?? (isRtl ? 'فشل الطلب / حدث استثناء' : 'Request Failed / Exception Encountered'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        log.errorMessage ?? (isRtl ? 'حدث خطأ في النظام أثناء معالجة هذا الطلب.' : 'An HTTP or application error occurred during this request.'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Request ID Section
                        if (log.requestId != null && log.requestId!.isNotEmpty) ...[
                          _buildSectionHeader(
                            Icons.fingerprint_rounded,
                            isRtl ? 'معرّف الطلب والتتبع (Correlation ID)' : 'Distributed Request & Correlation ID',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    log.requestId!,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _copyToClipboard(context, log.requestId!, 'Request ID', isRtl),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.content_copy_rounded, size: 14, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 4),
                                        Text(
                                          isRtl ? 'نسخ' : 'Copy',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Metadata Grid Card
                        _buildSectionHeader(
                          Icons.info_outline_rounded,
                          isRtl ? 'بيانات التنفيذ والشبكة' : 'Execution & Network Metadata',
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (log.endpoint != null && log.endpoint!.isNotEmpty) ...[
                                _buildMetaRow(
                                  isRtl ? 'طريقة HTTP والرابط:' : 'HTTP Method & URL:',
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildMethodBadge(log.httpMethod),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          log.endpoint!,
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  isDark,
                                ),
                                const Divider(height: 16),
                              ],
                              _buildMetaRow(
                                isRtl ? 'عنوان IP للعميل:' : 'Client IP Address:',
                                Text(
                                  log.ipAddress ?? '—',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                ),
                                isDark,
                              ),
                              const Divider(height: 16),
                              _buildMetaRow(
                                isRtl ? 'الكيان المستهدف:' : 'Target Entity:',
                                Row(
                                  children: [
                                    Text(
                                      log.entityType,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    if (log.entityId > 0) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '#${log.entityId}',
                                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ],
                                ),
                                isDark,
                              ),
                              const Divider(height: 16),
                              _buildMetaRow(
                                isRtl ? 'المنفذ / المشرف:' : 'Performed By / Actor:',
                                log.performedBy != null
                                    ? Row(
                                        children: [
                                          Text(
                                            log.performedBy!.fullName,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              log.performedBy!.role,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                          if (log.performedBy!.email.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              '(${log.performedBy!.email})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ],
                                      )
                                    : Text(
                                        log.userId != null ? 'User ID #${log.userId}' : 'SYSTEM / Anonymous',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                isDark,
                              ),
                              if (log.userAgent != null && log.userAgent!.isNotEmpty) ...[
                                const Divider(height: 16),
                                _buildMetaRow(
                                  isRtl ? 'متصفح وجهاز العميل:' : 'User Agent / Client Device:',
                                  SelectableText(
                                    log.userAgent!,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                  ),
                                  isDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Payload Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(
                              Icons.data_object_rounded,
                              isRtl ? 'بيانات الطلب والتعديلات (Payload)' : 'Payload & Mutation Data',
                              isDark,
                            ),
                            InkWell(
                              onTap: () => _copyToClipboard(context, formattedJson, 'Payload JSON', isRtl),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.content_copy_rounded, size: 14, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 4),
                                    Text(
                                      isRtl ? 'نسخ JSON' : 'Copy JSON',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF090D16) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
                            ),
                          ),
                          child: SelectableText(
                            formattedJson,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF38BDF8),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Modal Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(isRtl ? 'إغلاق المعاينة' : 'Close Inspector'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, Widget value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }

  Widget _buildActionPill(String action, bool isDark) {
    final color = _getActionColor(action, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        action.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMethodBadge(String? method) {
    final m = (method ?? 'HTTP').toUpperCase();
    final color = _getMethodColor(m);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        m,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int? statusCode, bool? success, bool isDark) {
    final color = _getStatusColor(statusCode, success);
    final text = statusCode != null ? '$statusCode' : (success == true ? '200' : 'FAIL');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyBadge(int durationMs, bool isDark) {
    final color = _getDurationColor(durationMs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${durationMs}ms',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(translationProvider);
    final isRtl = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auditState = ref.watch(auditLogRepositoryProvider);

    final totalCount = auditState.totalElements;
    final successCount = auditState.logs.where((l) => l.success != false && (l.statusCode == null || l.statusCode! < 400)).length;
    final errorCount = auditState.logs.where((l) => l.success == false || (l.statusCode != null && l.statusCode! >= 400)).length;

    final validDurations = auditState.logs.where((l) => l.durationMs != null && l.durationMs! > 0).map((l) => l.durationMs!).toList();
    final avgDuration = validDurations.isNotEmpty
        ? (validDurations.reduce((a, b) => a + b) / validDurations.length).round()
        : 0;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Page Header
                _buildHeader(isRtl, isDark, auditState.isLoading),
                const SizedBox(height: 20),

                // 2. Stats Grid
                _buildStatsGrid(totalCount, successCount, errorCount, avgDuration, isRtl, isDark),
                const SizedBox(height: 20),

                // 3. Controls & Filter Bar
                _buildControlsBar(isRtl, isDark),
                const SizedBox(height: 20),

                // 4. Main Data Table & Pagination
                _buildTableCard(auditState, isRtl, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isRtl, bool isDark, bool isLoading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_edu_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isRtl ? 'سجل العمليات والتدقيق' : 'Audit & History Logs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isRtl
                      ? 'تتبع شامل لجميع العمليات الإدارية، طلبات HTTP، زمن الاستجابة، وسجلات الأمان في النظام.'
                      : 'Complete trace of system mutations, HTTP requests, response latencies, and security events.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _loadLogs(page: 0),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isRtl ? 'تحديث' : 'Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid(int total, int success, int errors, int avgLatency, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 4
            : (constraints.maxWidth >= 600 ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: crossAxisCount == 1 ? 3.4 : (crossAxisCount == 2 ? 2.4 : 2.1),
          children: [
            _buildStatCard(
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF2563EB),
              title: isRtl ? 'إجمالي العمليات المسجلة' : 'Total Audited Events',
              value: '$total',
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF10B981),
              title: isRtl ? 'العمليات الناجحة (الصفحة)' : 'Successful (Page)',
              value: '$success',
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.error_outline_rounded,
              iconColor: const Color(0xFFEF4444),
              title: isRtl ? 'الأخطاء والاستثناءات' : 'Errors & Failures',
              value: '$errors',
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.speed_rounded,
              iconColor: const Color(0xFF6366F1),
              title: isRtl ? 'متوسط زمن الاستجابة' : 'Avg Latency (Page)',
              value: '$avgLatency ms',
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _onFilterChange(),
            decoration: InputDecoration(
              hintText: isRtl
                  ? 'ابحث برقم الطلب، الرابط، المشرف، أو البيانات...'
                  : 'Search by Request ID, URL, actor, or payload...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onFilterChange();
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dropdowns & Date Pickers Wrap
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Entity Type Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      isRtl ? 'الكيان:' : 'Entity:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedEntityType,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        items: _entityTypes.map((e) {
                          return DropdownMenuItem<String>(
                            value: e['id'] as String,
                            child: Text(isRtl ? e['nameAr'] as String : e['nameEn'] as String),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedEntityType = val ?? '');
                          _onFilterChange();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Action Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      isRtl ? 'العملية:' : 'Action:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAction,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        items: _actions.map((a) {
                          return DropdownMenuItem<String>(
                            value: a['id'] as String,
                            child: Text(isRtl ? a['nameAr'] as String : a['nameEn'] as String),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedAction = val ?? '');
                          _onFilterChange();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Date Pickers: From
              InkWell(
                onTap: () => _pickDate(context, true),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 15, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        isRtl ? 'من:' : 'From:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _startDate.isNotEmpty ? _startDate : 'dd-mm-yyyy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _startDate.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                          color: _startDate.isNotEmpty
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_month_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      if (_startDate.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _startDate = '');
                            _onFilterChange();
                          },
                          child: const Icon(Icons.close_rounded, size: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Date Pickers: To
              InkWell(
                onTap: () => _pickDate(context, false),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded, size: 15, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        isRtl ? 'إلى:' : 'To:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _endDate.isNotEmpty ? _endDate : 'dd-mm-yyyy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _endDate.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                          color: _endDate.isNotEmpty
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_month_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      if (_endDate.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _endDate = '');
                            _onFilterChange();
                          },
                          child: const Icon(Icons.close_rounded, size: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Reset CTA
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: Text(isRtl ? 'إعادة ضبط' : 'Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(AuditLogState auditState, bool isRtl, bool isDark) {
    if (auditState.isLoading && auditState.logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text(
              isRtl ? 'جاري تحميل سجلات العمليات من قاعدة البيانات...' : 'Fetching audit records from database...',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (auditState.errorMessage != null && auditState.logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              isRtl ? 'تعذر جلب سجلات التدقيق' : 'Unable to Fetch Audit Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              auditState.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadLogs(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isRtl ? 'إعادة المحاولة' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (auditState.logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: Color(0xFF2563EB), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              isRtl ? 'لم يتم العثور على سجلات' : 'No Audit Logs Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isRtl
                  ? 'جرب تغيير كلمات البحث، تصفية العمليات، أو الفترة الزمنية المحددة.'
                  : 'Try adjusting your search keywords, action filters, or selected date range.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(isRtl ? 'إعادة ضبط التصفية' : 'Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isWide)
                _buildDesktopTable(auditState.logs, isRtl, isDark)
              else
                _buildMobileCardList(auditState.logs, isRtl, isDark),

              // Pagination Footer
              _buildPaginationFooter(auditState, isRtl, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<AuditLog> logs, bool isRtl, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        dataRowMaxHeight: 64,
        dataRowMinHeight: 56,
        horizontalMargin: 20,
        columnSpacing: 24,
        columns: [
          DataColumn(label: Text(isRtl ? 'الوقت والتاريخ' : 'Timestamp', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(isRtl ? 'معرّف الطلب' : 'Request ID', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(isRtl ? 'العملية والكيان' : 'Action & Entity', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(isRtl ? 'رابط الطلب' : 'HTTP Endpoint', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(isRtl ? 'الحالة والزمن' : 'Status & Latency', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(isRtl ? 'المنفذ / المشرف' : 'Actor / User', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(isRtl ? 'عنوان IP' : 'Client IP', style: const TextStyle(fontWeight: FontWeight.w700))),
          DataColumn(label: Text(isRtl ? 'معاينة' : 'Inspect', style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
        rows: logs.map((log) {
          final isErrorRow = log.success == false || (log.statusCode != null && log.statusCode! >= 400);

          return DataRow(
            color: isErrorRow
                ? WidgetStateProperty.all(const Color(0xFFEF4444).withValues(alpha: isDark ? 0.08 : 0.04))
                : null,
            cells: [
              // Timestamp
              DataCell(
                Text(
                  _formatDate(log.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),

              // Request ID (Clickable copy)
              DataCell(
                log.requestId != null && log.requestId!.isNotEmpty
                    ? InkWell(
                        onTap: () => _copyToClipboard(context, log.requestId!, 'Request ID', isRtl),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fingerprint_rounded, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                log.requestId!.length > 12 ? '${log.requestId!.substring(0, 10)}...' : log.requestId!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.content_copy_rounded, size: 12, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      )
                    : const Text('—', style: TextStyle(color: Colors.grey)),
              ),

              // Action & Entity
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionPill(log.action, isDark),
                    if (log.entityType.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${log.entityType}${log.entityId > 0 ? " #${log.entityId}" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // HTTP Endpoint
              DataCell(
                log.endpoint != null && log.endpoint!.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMethodBadge(log.httpMethod),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              log.endpoint!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const Text('—', style: TextStyle(color: Colors.grey)),
              ),

              // Status & Latency
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(log.statusCode, log.success, isDark),
                    if (log.durationMs != null) ...[
                      const SizedBox(width: 6),
                      _buildLatencyBadge(log.durationMs!, isDark),
                    ],
                  ],
                ),
              ),

              // Actor / User
              DataCell(
                log.performedBy != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            log.performedBy!.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (log.performedBy!.role.isNotEmpty)
                            Text(
                              log.performedBy!.role,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.dns_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            log.userId != null ? 'User #${log.userId}' : 'SYSTEM',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),

              // Client IP
              DataCell(
                Text(
                  log.ipAddress ?? '—',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),

              // Inspect Button
              DataCell(
                ElevatedButton.icon(
                  onPressed: () => _showInspectorModal(context, log, isRtl, isDark),
                  icon: const Icon(Icons.visibility_rounded, size: 14),
                  label: Text(isRtl ? 'معاينة' : 'Inspect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                    foregroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCardList(List<AuditLog> logs, bool isRtl, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => Divider(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        height: 24,
      ),
      itemBuilder: (context, index) {
        final log = logs[index];
        final isError = log.success == false || (log.statusCode != null && log.statusCode! >= 400);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isError
                ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.08 : 0.03)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildActionPill(log.action, isDark),
                      _buildStatusBadge(log.statusCode, log.success, isDark),
                      if (log.durationMs != null) _buildLatencyBadge(log.durationMs!, isDark),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showInspectorModal(context, log, isRtl, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            isRtl ? 'معاينة' : 'Inspect',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    log.entityType,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  if (log.entityId > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '#${log.entityId}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(log.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (log.endpoint != null && log.endpoint!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildMethodBadge(log.httpMethod),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        log.endpoint!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.performedBy != null
                        ? '${log.performedBy!.fullName} (${log.performedBy!.role})'
                        : (log.userId != null ? 'User #${log.userId}' : 'SYSTEM'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    log.ipAddress ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(AuditLogState auditState, bool isRtl, bool isDark) {
    final startIdx = auditState.currentPage * auditState.filter.size + 1;
    final endIdx = auditState.currentPage * auditState.filter.size + auditState.logs.length;
    final total = auditState.totalElements;
    final totalPages = auditState.totalPages;
    final current = auditState.currentPage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;

          final paginationInfo = Text(
            isRtl
                ? 'عرض $startIdx إلى $endIdx من أصل $total سجل'
                : 'Showing $startIdx to $endIdx of $total entries',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          );

          final pageSizeSelector = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRtl ? 'لكل صفحة:' : 'Per page:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _pageSize,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    items: _pageSizeList.map((sz) {
                      return DropdownMenuItem<int>(
                        value: sz,
                        child: Text('$sz'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _pageSize = val);
                        _loadLogs(page: 0);
                      }
                    },
                  ),
                ),
              ),
            ],
          );

          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: current > 0 ? () => _loadLogs(page: 0) : null,
                icon: const Icon(Icons.first_page_rounded, size: 18),
                splashRadius: 18,
              ),
              IconButton(
                onPressed: current > 0 ? () => _loadLogs(page: current - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                splashRadius: 18,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${current + 1} / ${totalPages > 0 ? totalPages : 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: current < totalPages - 1 ? () => _loadLogs(page: current + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                splashRadius: 18,
              ),
              IconButton(
                onPressed: current < totalPages - 1 ? () => _loadLogs(page: totalPages - 1) : null,
                icon: const Icon(Icons.last_page_rounded, size: 18),
                splashRadius: 18,
              ),
            ],
          );

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    paginationInfo,
                    const SizedBox(width: 20),
                    pageSizeSelector,
                  ],
                ),
                controls,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  paginationInfo,
                  pageSizeSelector,
                ],
              ),
              const SizedBox(height: 10),
              Center(child: controls),
            ],
          );
        },
      ),
    );
  }
}
