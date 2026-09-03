import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/partner_request_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

enum _ViewMode { grid, table }
enum _ActiveTab { pending, approved, rejected, all }

class PartnerRequestsCrudScreen extends ConsumerStatefulWidget {
  const PartnerRequestsCrudScreen({super.key});

  @override
  ConsumerState<PartnerRequestsCrudScreen> createState() => _PartnerRequestsCrudScreenState();
}

class _PartnerRequestsCrudScreenState extends ConsumerState<PartnerRequestsCrudScreen> {
  _ActiveTab _activeTab = _ActiveTab.pending;
  _ViewMode _viewMode = _ViewMode.grid;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _copiedCrId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyCr(String? cr, int id, bool isRtl) {
    if (cr == null || cr.isEmpty) return;
    Clipboard.setData(ClipboardData(text: cr));
    setState(() => _copiedCrId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRtl ? 'تم نسخ رقم السجل التجاري: $cr' : 'CR Number copied: $cr',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedCrId = null);
    });
  }

  Future<void> _launchExternal(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  List<PartnerRequest> _filterRequests(List<PartnerRequest> all) {
    List<PartnerRequest> list = all;

    if (_activeTab == _ActiveTab.pending) {
      list = list.where((r) => r.status == PartnerRequestStatus.PENDING).toList();
    } else if (_activeTab == _ActiveTab.approved) {
      list = list.where((r) => r.status == PartnerRequestStatus.APPROVED).toList();
    } else if (_activeTab == _ActiveTab.rejected) {
      list = list.where((r) => r.status == PartnerRequestStatus.REJECTED).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((r) {
        return r.storeNameEn.toLowerCase().contains(q) ||
            r.storeNameAr.toLowerCase().contains(q) ||
            r.applicantName.toLowerCase().contains(q) ||
            r.applicantEmail.toLowerCase().contains(q) ||
            r.applicantPhone.toLowerCase().contains(q) ||
            (r.cityNameEn != null && r.cityNameEn!.toLowerCase().contains(q)) ||
            (r.cityNameAr != null && r.cityNameAr!.toLowerCase().contains(q)) ||
            (r.categoryNameEn != null && r.categoryNameEn!.toLowerCase().contains(q)) ||
            (r.categoryNameAr != null && r.categoryNameAr!.toLowerCase().contains(q)) ||
            (r.crNumber != null && r.crNumber!.toLowerCase().contains(q)) ||
            (r.vatNumber != null && r.vatNumber!.toLowerCase().contains(q));
      }).toList();
    }

    return list;
  }

  void _showApproveDialog(BuildContext context, PartnerRequest req, bool isRtl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isRtl ? 'اعتماد شريك المتجر؟' : 'Approve Store Partner?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRtl
                  ? 'هل أنت متأكد من اعتماد متجر ${req.storeNameAr.isNotEmpty ? req.storeNameAr : req.storeNameEn}؟'
                  : 'Are you sure you want to approve ${req.storeNameEn}?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRtl
                  ? 'سيتم تلقائياً إنشاء المتجر الموثق وتفعيل صلاحية مدير المتجر للبريد:\n${req.applicantEmail}'
                  : 'This will automatically create the verified store and grant Store Manager access to:\n${req.applicantEmail}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: Text(
              isRtl ? 'نعم، اعتماد وإنشاء المتجر' : 'Yes, Approve & Provision',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final approved = await ref
                  .read(partnerRequestRepositoryProvider.notifier)
                  .approveRequest(req.id);
              if (mounted) {
                _showSuccessApproveDialog(context, approved ?? req, isRtl, isDark);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessApproveDialog(
      BuildContext context, PartnerRequest req, bool isRtl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isRtl ? 'تم اعتماد المتجر بنجاح!' : 'Store Partner Approved!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'تم إنشاء المتجر بنجاح وتفعيل حساب إدارة المتجر للمشرف ${req.applicantEmail}.'
              : 'Store created successfully. Store Manager account activated for ${req.applicantEmail}.',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isRtl ? 'حسناً' : 'Done'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, PartnerRequest req, bool isRtl, bool isDark) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isRtl ? 'رفض طلب الشراكة' : 'Reject Partner Application',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRtl ? 'سبب الرفض' : 'Reason for Rejection',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: isRtl
                    ? 'مثال: السجل التجاري غير صالح أو غير مقروء...'
                    : 'e.g. Commercial Registration (CR) is invalid or unreadable...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              final reason = reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : (isRtl ? 'لم يستوف متطلبات الشراكة' : 'Did not meet requirements');
              Navigator.pop(ctx);
              ref.read(partnerRequestRepositoryProvider.notifier).rejectRequest(req.id, reason);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isRtl ? 'تم تسجيل رفض طلب الشراكة.' : 'Application rejected.'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              isRtl ? 'تأكيد الرفض' : 'Reject Application',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showInspectDetailsModal(BuildContext context, PartnerRequest req, bool isRtl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.storefront_outlined, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl
                                ? (req.storeNameAr.isNotEmpty ? req.storeNameAr : req.storeNameEn)
                                : req.storeNameEn,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isRtl
                                ? 'تفاصيل طلب الشراكة والتوثيق والامتثال التجاري'
                                : 'Merchant Application & Regulatory Compliance Review',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Store Identity
                      _buildModalSectionHeader(
                        icon: Icons.store_outlined,
                        title: isRtl ? 'هوية المتجر' : 'Store Identity',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(isRtl ? 'اسم المتجر (EN):' : 'Store Name (EN):', req.storeNameEn, isDark, isBold: true),
                      _buildInfoRow(isRtl ? 'اسم المتجر (AR):' : 'Store Name (AR):', req.storeNameAr.isNotEmpty ? req.storeNameAr : '—', isDark, isBold: true),
                      _buildInfoRow(
                        isRtl ? 'النشاط:' : 'Category:',
                        isRtl ? (req.categoryNameAr ?? req.categoryNameEn ?? 'عام') : (req.categoryNameEn ?? 'General'),
                        isDark,
                      ),
                      _buildInfoRow(
                        isRtl ? 'المدينة:' : 'City:',
                        isRtl ? (req.cityNameAr ?? req.cityNameEn ?? 'المملكة') : (req.cityNameEn ?? 'Saudi Arabia'),
                        isDark,
                      ),
                      if (req.contactAddress != null && req.contactAddress!.isNotEmpty)
                        _buildInfoRow(isRtl ? 'العنوان:' : 'Address:', req.contactAddress!, isDark),

                      const SizedBox(height: 20),

                      // Section 2: Commercial & Legal
                      _buildModalSectionHeader(
                        icon: Icons.verified_user_outlined,
                        title: isRtl ? 'السجل التجاري والتوثيق' : 'Commercial & Legal',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isRtl ? 'السجل التجاري:' : 'Commercial Reg (CR):',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    req.crNumber ?? 'N/A',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                                if (req.crNumber != null && req.crNumber!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _copyCr(req.crNumber, req.id, isRtl),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        _copiedCrId == req.id ? Icons.check : Icons.content_copy,
                                        size: 16,
                                        color: _copiedCrId == req.id ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (req.vatNumber != null && req.vatNumber!.isNotEmpty)
                        _buildInfoRow(isRtl ? 'الرقم الضريبي:' : 'VAT Tax Number:', req.vatNumber!, isDark, isMonospace: true),
                      if (req.website != null && req.website!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isRtl ? 'الموقع الإلكتروني:' : 'Website URL:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              InkWell(
                                onTap: () => _launchExternal(req.website!),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      req.website!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.open_in_new, size: 14, color: Color(0xFF2563EB)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isRtl ? 'الحالة الحالية:' : 'Current Status:',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            _buildStatusPill(req.status, isRtl, isDark),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 3: Applicant & Store Manager
                      _buildModalSectionHeader(
                        icon: Icons.contact_page_outlined,
                        title: isRtl ? 'بيانات مقدم الطلب والمشرف' : 'Applicant / Store Manager',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 460;
                          final cards = [
                            _buildMiniContactCard(
                              icon: Icons.person_outline,
                              label: isRtl ? 'اسم المسؤول' : 'Manager Name',
                              value: req.applicantName,
                              isDark: isDark,
                            ),
                            _buildMiniContactCard(
                              icon: Icons.email_outlined,
                              label: isRtl ? 'البريد الإلكتروني' : 'Email Address',
                              value: req.applicantEmail,
                              isDark: isDark,
                              onTap: () => _launchExternal('mailto:${req.applicantEmail}'),
                              isLink: true,
                            ),
                            _buildMiniContactCard(
                              icon: Icons.phone_outlined,
                              label: isRtl ? 'رقم الجوال' : 'Contact Phone',
                              value: req.applicantPhone,
                              isDark: isDark,
                              onTap: () => _launchExternal('tel:${req.applicantPhone}'),
                              isLink: true,
                            ),
                          ];

                          if (isNarrow) {
                            return Column(
                              children: cards
                                  .map((c) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: c,
                                      ))
                                  .toList(),
                            );
                          } else {
                            return Row(
                              children: cards
                                  .map((c) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: c,
                                        ),
                                      ))
                                  .toList(),
                            );
                          }
                        },
                      ),

                      // Section 4: Store Bio
                      if ((req.descriptionEn != null && req.descriptionEn!.isNotEmpty) ||
                          (req.descriptionAr != null && req.descriptionAr!.isNotEmpty)) ...[
                        const SizedBox(height: 20),
                        _buildModalSectionHeader(
                          icon: Icons.notes_outlined,
                          title: isRtl ? 'نبذة عن المتجر' : 'Store Description & Bio',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        if (req.descriptionEn != null && req.descriptionEn!.isNotEmpty) ...[
                          Text(
                            isRtl ? 'الوصف بالإنجليزي:' : 'English Bio:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              req.descriptionEn!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (req.descriptionAr != null && req.descriptionAr!.isNotEmpty) ...[
                          Text(
                            isRtl ? 'الوصف بالعربي:' : 'Arabic Bio:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              req.descriptionAr!,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],

                      // Section 5: Rejection Reason
                      if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildModalSectionHeader(
                          icon: Icons.info_outline,
                          title: isRtl ? 'سبب الرفض المسجل' : 'Rejection Reason Provided',
                          isDark: isDark,
                          isDanger: true,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            req.rejectionReason!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Modal Footer
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isRtl ? 'إغلاق' : 'Close'),
                    ),
                    if (req.status == PartnerRequestStatus.PENDING) ...[
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.close, size: 16),
                            label: Text(isRtl ? 'رفض الطلب' : 'Decline Application'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showRejectDialog(context, req, isRtl, isDark);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.verified_outlined, size: 16),
                            label: Text(isRtl ? 'اعتماد وإنشاء المتجر' : 'Approve & Provision'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showApproveDialog(context, req, isRtl, isDark);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    bool isDanger = false,
  }) {
    final color = isDanger
        ? const Color(0xFFDC2626)
        : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDanger ? const Color(0xFFDC2626) : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isBold = false, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniContactCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    VoidCallback? onTap,
    bool isLink = false,
  }) {
    final content = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLink
                        ? const Color(0xFF2563EB)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: isLink ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: content,
      );
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final partnerState = ref.watch(partnerRequestRepositoryProvider);
    final allRequests = partnerState.requests;
    final filteredRequests = _filterRequests(allRequests);

    final pendingCount = allRequests.where((r) => r.status == PartnerRequestStatus.PENDING).length;
    final approvedCount = allRequests.where((r) => r.status == PartnerRequestStatus.APPROVED).length;
    final rejectedCount = allRequests.where((r) => r.status == PartnerRequestStatus.REJECTED).length;
    final totalCount = allRequests.length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () => ref.read(partnerRequestRepositoryProvider.notifier).fetchRequests(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Page Header Block
                _buildHeaderBlock(isRtl, isDark),
                const SizedBox(height: 20),

                // 2. Status Tabs Bar & Toolbar
                _buildTabsAndToolbar(
                  isRtl: isRtl,
                  isDark: isDark,
                  pendingCount: pendingCount,
                  approvedCount: approvedCount,
                  rejectedCount: rejectedCount,
                  totalCount: totalCount,
                ),
                const SizedBox(height: 20),

                // 3. Content: Loading / Empty / Grid / Table
                if (partnerState.isLoading && allRequests.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredRequests.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else if (_viewMode == _ViewMode.grid) ...[
                  _buildCardsGrid(filteredRequests, isRtl, isDark),
                ] else ...[
                  _buildTableView(filteredRequests, isRtl, isDark),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Block
  Widget _buildHeaderBlock(bool isRtl, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.handshake_outlined, color: Color(0xFFD97706), size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRtl ? 'طلبات شراكة المتاجر' : 'Merchant Partner Requests',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRtl
                    ? 'مراجعة طلبات الانضمام والتحقق من السجلات التجارية واعتماد لوحة إدارة المتجر.'
                    : 'Review merchant applications, verify commercial registration (CR), and provision store portals.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Status Tabs Bar & Toolbar
  Widget _buildTabsAndToolbar({
    required bool isRtl,
    required bool isDark,
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required int totalCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWrap = constraints.maxWidth < 880;

          final tabsGroup = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton(
                  tab: _ActiveTab.pending,
                  label: isRtl ? 'قيد المراجعة' : 'Pending',
                  icon: Icons.hourglass_top_rounded,
                  count: pendingCount,
                  isProminentBadge: pendingCount > 0,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildTabButton(
                  tab: _ActiveTab.approved,
                  label: isRtl ? 'المعتمدة' : 'Approved',
                  icon: Icons.check_circle_outline,
                  count: approvedCount,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildTabButton(
                  tab: _ActiveTab.rejected,
                  label: isRtl ? 'المرفوضة' : 'Rejected',
                  icon: Icons.cancel_outlined,
                  count: rejectedCount,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildTabButton(
                  tab: _ActiveTab.all,
                  label: isRtl ? 'الكل' : 'All',
                  icon: Icons.list_alt_rounded,
                  count: totalCount,
                  isDark: isDark,
                ),
              ],
            ),
          );

          final rightControls = Row(
            mainAxisSize: isWrap ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // View Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(
                      mode: _ViewMode.grid,
                      icon: Icons.grid_view_rounded,
                      label: isRtl ? 'بطاقات' : 'Cards',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 2),
                    _buildViewToggleButton(
                      mode: _ViewMode.table,
                      icon: Icons.view_list_rounded,
                      label: isRtl ? 'جدول' : 'Table',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Search Bar
              Expanded(
                flex: isWrap ? 1 : 0,
                child: SizedBox(
                  width: isWrap ? null : 250,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      hintText: isRtl
                          ? 'ابحث بالمتجر، السجل، المدينة...'
                          : 'Search store, CR, city...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

          if (isWrap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabsGroup,
                const SizedBox(height: 12),
                rightControls,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                tabsGroup,
                rightControls,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTabButton({
    required _ActiveTab tab,
    required String label,
    required IconData icon,
    required int count,
    required bool isDark,
    bool isProminentBadge = false,
  }) {
    final isActive = _activeTab == tab;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeTab = tab),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? const Color(0xFF16A34A)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF16A34A)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isProminentBadge
                      ? const Color(0xFFD97706)
                      : (isActive
                          ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isProminentBadge
                        ? Colors.white
                        : (isActive
                            ? const Color(0xFF16A34A)
                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required _ViewMode mode,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isActive = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? const Color(0xFF16A34A)
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive
                    ? const Color(0xFF16A34A)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading State
  Widget _buildLoadingState(bool isRtl, bool isDark) {
    return CrudLoadingWidget(
      titleEn: 'Loading Partner Applications...',
      titleAr: 'جاري تحميل طلبات الشراكة والانضمام...',
      subtitleEn: 'Fetching business proposals and review statuses...',
      subtitleAr: 'جاري جلب ملفات التجار وحالات المراجعة والاعتماد...',
      icon: Icons.handshake_rounded,
      isRtl: isRtl,
      isDark: isDark,
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 14),
          Text(
            isRtl ? 'لا توجد طلبات شراكة' : 'No Partner Requests Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRtl
                ? 'لا توجد طلبات انضمام في هذا التبويب أو مطابقة للبحث الحالي.'
                : 'There are no merchant applications matching the current filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (_searchQuery.isNotEmpty || _activeTab != _ActiveTab.all) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(isRtl ? 'إعادة ضبط التصفية' : 'Reset Filters'),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeTab = _ActiveTab.all;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // 3. Grid Cards View
  Widget _buildCardsGrid(List<PartnerRequest> requests, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 1200 ? 3 : (width >= 720 ? 2 : 1);

        if (crossAxisCount == 1) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildMerchantCard(requests[index], isRtl, isDark),
          );
        }

        // Multi-column row layout
        final rows = <Widget>[];
        for (int i = 0; i < requests.length; i += crossAxisCount) {
          final rowChildren = <Widget>[];
          for (int j = 0; j < crossAxisCount; j++) {
            if (i + j < requests.length) {
              rowChildren.add(
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildMerchantCard(requests[i + j], isRtl, isDark),
                  ),
                ),
              );
            } else {
              rowChildren.add(const Expanded(child: SizedBox()));
            }
          }
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rowChildren,
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }

  // Single Merchant Application Card
  Widget _buildMerchantCard(PartnerRequest req, bool isRtl, bool isDark) {
    final isPending = req.status == PartnerRequestStatus.PENDING;
    final isApproved = req.status == PartnerRequestStatus.APPROVED;
    final dateStr = req.createdAt != null
        ? DateFormat.yMMMd().format(req.createdAt!)
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.4 : 0.6)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.1 : 0.06)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Card Header: Brand, Category, Status & 3-Dots Menu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF16A34A),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Titles & Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl
                            ? (req.storeNameAr.isNotEmpty ? req.storeNameAr : req.storeNameEn)
                            : req.storeNameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (isRtl && req.storeNameEn.isNotEmpty && req.storeNameEn != req.storeNameAr)
                        Text(
                          req.storeNameEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      if (!isRtl && req.storeNameAr.isNotEmpty && req.storeNameAr != req.storeNameEn)
                        Text(
                          req.storeNameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Category Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.category_outlined, size: 12, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              isRtl
                                  ? (req.categoryNameAr ?? req.categoryNameEn ?? 'تجزئة')
                                  : (req.categoryNameEn ?? 'Retail'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status pill & 3-Dots Menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusPill(req.status, isRtl, isDark),
                    _buildCardActionMenu(req, isRtl, isDark),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

          // 2. Card Body Summary: City, Date, CR, Manager
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City & Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_outlined, size: 13, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            isRtl
                                ? (req.cityNameAr ?? req.cityNameEn ?? 'المملكة')
                                : (req.cityNameEn ?? 'Saudi Arabia'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Facts Grid: CR & Manager
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (req.crNumber != null && req.crNumber!.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isRtl ? 'السجل التجاري:' : 'CR Number:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    req.crNumber!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _copyCr(req.crNumber, req.id, isRtl),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      _copiedCrId == req.id ? Icons.check : Icons.content_copy,
                                      size: 14,
                                      color: _copiedCrId == req.id
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isRtl ? 'المسؤول:' : 'Manager:',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                req.applicantName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Direct Contact Quick Links Strip
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _launchExternal('mailto:${req.applicantEmail}'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  req.applicantEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _launchExternal('tel:${req.applicantPhone}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              req.applicantPhone,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Rejection note
                if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            req.rejectionReason!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Card Footer Actions
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(
                    isRtl ? 'معاينة الطلب' : 'Inspect Details',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _showInspectDetailsModal(context, req, isRtl, isDark),
                ),
                if (isPending) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.verified_outlined, size: 16),
                    label: Text(
                      isRtl ? 'اعتماد المتجر' : 'Approve Store',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showApproveDialog(context, req, isRtl, isDark),
                  ),
                ] else if (isApproved) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        isRtl ? 'تم إنشاء المتجر بنجاح' : 'Store Provisioned',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3-Dots Quick Action Menu on Card
  Widget _buildCardActionMenu(PartnerRequest req, bool isRtl, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        if (action == 'inspect') {
          _showInspectDetailsModal(context, req, isRtl, isDark);
        } else if (action == 'email') {
          _launchExternal('mailto:${req.applicantEmail}');
        } else if (action == 'phone') {
          _launchExternal('tel:${req.applicantPhone}');
        } else if (action == 'copy_cr') {
          _copyCr(req.crNumber, req.id, isRtl);
        } else if (action == 'website' && req.website != null) {
          _launchExternal(req.website!);
        } else if (action == 'approve') {
          _showApproveDialog(context, req, isRtl, isDark);
        } else if (action == 'reject') {
          _showRejectDialog(context, req, isRtl, isDark);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'inspect',
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18),
              const SizedBox(width: 10),
              Text(isRtl ? 'معاينة التفاصيل' : 'Inspect Details', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              const Icon(Icons.email_outlined, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Text(isRtl ? 'إرسال بريد' : 'Email Manager', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'phone',
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Text(isRtl ? 'اتصال هاتفي' : 'Call Phone', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        if (req.crNumber != null && req.crNumber!.isNotEmpty)
          PopupMenuItem(
            value: 'copy_cr',
            child: Row(
              children: [
                const Icon(Icons.content_copy, size: 18),
                const SizedBox(width: 10),
                Text(isRtl ? 'نسخ رقم السجل' : 'Copy CR Code', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        if (req.website != null && req.website!.isNotEmpty)
          PopupMenuItem(
            value: 'website',
            child: Row(
              children: [
                const Icon(Icons.open_in_new, size: 18),
                const SizedBox(width: 10),
                Text(isRtl ? 'موقع المتجر' : 'Store Website', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        if (req.status == PartnerRequestStatus.PENDING) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 10),
                Text(
                  isRtl ? 'اعتماد وإنشاء المتجر' : 'Approve Store',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFDC2626)),
                const SizedBox(width: 10),
                Text(
                  isRtl ? 'رفض الطلب' : 'Decline Request',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 4. High-Density Table View
  Widget _buildTableView(List<PartnerRequest> requests, bool isRtl, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: [
              DataColumn(
                label: Text(
                  isRtl ? 'المتجر والنشاط' : 'Store & Category',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'مقدم الطلب' : 'Applicant / Manager',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'المدينة' : 'City',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'السجل والرقم الضريبي' : 'CR & VAT',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'الحالة' : 'Status',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'تاريخ التقديم' : 'Applied Date',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'الإجراءات' : 'Actions',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
            rows: requests.map((req) {
              final isPending = req.status == PartnerRequestStatus.PENDING;
              final dateStr = req.createdAt != null
                  ? DateFormat.yMMMd().format(req.createdAt!)
                  : '—';
              final timeStr = req.createdAt != null
                  ? DateFormat.jm().format(req.createdAt!)
                  : '';

              return DataRow(
                cells: [
                  // Store & Category
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.storefront_outlined, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRtl
                                  ? (req.storeNameAr.isNotEmpty ? req.storeNameAr : req.storeNameEn)
                                  : req.storeNameEn,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              isRtl
                                  ? (req.categoryNameAr ?? req.categoryNameEn ?? 'عام')
                                  : (req.categoryNameEn ?? 'General'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Applicant
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.applicantName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        InkWell(
                          onTap: () => _launchExternal('mailto:${req.applicantEmail}'),
                          child: Text(
                            req.applicantEmail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _launchExternal('tel:${req.applicantPhone}'),
                          child: Text(
                            req.applicantPhone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // City
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isRtl
                            ? (req.cityNameAr ?? req.cityNameEn ?? 'المملكة')
                            : (req.cityNameEn ?? 'Saudi Arabia'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),

                  // CR & VAT
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (req.crNumber != null && req.crNumber!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CR: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                req.crNumber!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyCr(req.crNumber, req.id, isRtl),
                                child: Icon(
                                  _copiedCrId == req.id ? Icons.check : Icons.content_copy,
                                  size: 13,
                                  color: _copiedCrId == req.id
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        if (req.vatNumber != null && req.vatNumber!.isNotEmpty)
                          Text(
                            'VAT: ${req.vatNumber}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        if ((req.crNumber == null || req.crNumber!.isEmpty) &&
                            (req.vatNumber == null || req.vatNumber!.isEmpty))
                          const Text('—', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),

                  // Status
                  DataCell(_buildStatusPill(req.status, isRtl, isDark)),

                  // Date
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _showInspectDetailsModal(context, req, isRtl, isDark),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility_outlined, size: 14),
                              const SizedBox(width: 4),
                              Text(isRtl ? 'معاينة' : 'Inspect', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.check, size: 18, color: Color(0xFF16A34A)),
                            tooltip: isRtl ? 'اعتماد وإنشاء المتجر' : 'Approve & Provision',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => _showApproveDialog(context, req, isRtl, isDark),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Color(0xFFDC2626)),
                            tooltip: isRtl ? 'رفض الطلب' : 'Reject application',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => _showRejectDialog(context, req, isRtl, isDark),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Status Pill with colored dot
  Widget _buildStatusPill(PartnerRequestStatus status, bool isRtl, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case PartnerRequestStatus.PENDING:
        bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = isRtl ? 'قيد المراجعة' : 'Pending';
        break;
      case PartnerRequestStatus.APPROVED:
        bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = isRtl ? 'معتمد' : 'Approved';
        break;
      case PartnerRequestStatus.REJECTED:
        bg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = isRtl ? 'مرفوض' : 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
