import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/services/admin_user_repository.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../core/widgets/custom_select_widget.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class UsersCrudScreen extends ConsumerStatefulWidget {
  const UsersCrudScreen({super.key});

  @override
  ConsumerState<UsersCrudScreen> createState() => _UsersCrudScreenState();
}

class _UsersCrudScreenState extends ConsumerState<UsersCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL'; // 'ALL' | 'SUPER_ADMIN' | 'CONTENT_MANAGER' | 'SUPPORT' | 'ANALYST' | 'STORE_MANAGER'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUserRepositoryProvider.notifier).fetchAdmins();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await ref.read(adminUserRepositoryProvider.notifier).fetchAdmins();
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
        });
      }
    });
  }

  String _normalizeRole(String role) {
    final r = role.toUpperCase().trim();
    if (r == 'SUPER_ADMIN' || r == 'SUPERADMIN' || r == 'ROLE_ADMIN' || r == 'ADMIN' || r == 'SUPER') {
      return 'SUPER_ADMIN';
    }
    if (r == 'CONTENT_MANAGER' || r == 'CONTENT' || r == 'EDITOR') {
      return 'CONTENT_MANAGER';
    }
    if (r == 'SUPPORT' || r == 'SUPPORT_AGENT' || r == 'ROLE_SUPPORT') {
      return 'SUPPORT';
    }
    if (r == 'ANALYST' || r == 'DATA_ANALYST') {
      return 'ANALYST';
    }
    if (r == 'STORE_MANAGER' || r == 'STORE_ADMIN' || r == 'ROLE_MANAGER' || r == 'MANAGER') {
      return 'STORE_MANAGER';
    }
    return r;
  }

  List<AdminUser> _getFilteredAdmins(List<AdminUser> allAdmins) {
    var list = allAdmins;

    if (_selectedRoleFilter != 'ALL') {
      list = list.where((a) => _normalizeRole(a.role) == _selectedRoleFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) {
        final name = a.fullName.toLowerCase();
        final email = a.email.toLowerCase();
        final role = a.role.toLowerCase();
        final roleLabelEn = _getRoleLabel(a.role, false).toLowerCase();
        final roleLabelAr = _getRoleLabel(a.role, true).toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            role.contains(q) ||
            roleLabelEn.contains(q) ||
            roleLabelAr.contains(q);
      }).toList();
    }

    return list;
  }

  // --- Helper Getters for Role Styles ---
  IconData _getRoleIcon(String rawRole) {
    final role = _normalizeRole(rawRole);
    switch (role) {
      case 'SUPER_ADMIN':
        return Icons.security_rounded;
      case 'CONTENT_MANAGER':
        return Icons.edit_note_rounded;
      case 'SUPPORT':
        return Icons.support_agent_rounded;
      case 'ANALYST':
        return Icons.insights_rounded;
      case 'STORE_MANAGER':
        return Icons.storefront_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  String _getRoleLabel(String rawRole, bool isRtl) {
    final role = _normalizeRole(rawRole);
    switch (role) {
      case 'SUPER_ADMIN':
        return isRtl ? 'مشرف عام' : 'Super Administrator';
      case 'CONTENT_MANAGER':
        return isRtl ? 'مدير المحتوى والعروض' : 'Content Manager';
      case 'SUPPORT':
        return isRtl ? 'أخصائي الدعم الفني' : 'Support Specialist';
      case 'ANALYST':
        return isRtl ? 'محلل بيانات وتقارير' : 'Data Analyst';
      case 'STORE_MANAGER':
        return isRtl ? 'مدير متجر' : 'Store Manager';
      default:
        return rawRole;
    }
  }

  Color _getRoleBgColor(String rawRole, bool isDark) {
    final role = _normalizeRole(rawRole);
    switch (role) {
      case 'SUPER_ADMIN':
        return isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7);
      case 'CONTENT_MANAGER':
        return isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF);
      case 'SUPPORT':
        return isDark ? const Color(0xFF581C87).withValues(alpha: 0.35) : const Color(0xFFFAF5FF);
      case 'ANALYST':
        return isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5);
      case 'STORE_MANAGER':
        return isDark ? const Color(0xFF134E4A).withValues(alpha: 0.35) : const Color(0xFFCCFBF1);
      default:
        return isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    }
  }

  Color _getRoleTextColor(String rawRole, bool isDark) {
    final role = _normalizeRole(rawRole);
    switch (role) {
      case 'SUPER_ADMIN':
        return isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
      case 'CONTENT_MANAGER':
        return isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
      case 'SUPPORT':
        return isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE);
      case 'ANALYST':
        return isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
      case 'STORE_MANAGER':
        return isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    }
  }

  Color _getRoleBorderColor(String rawRole, bool isDark) {
    final role = _normalizeRole(rawRole);
    switch (role) {
      case 'SUPER_ADMIN':
        return isDark ? const Color(0xFFD97706).withValues(alpha: 0.5) : const Color(0xFFFDE68A);
      case 'CONTENT_MANAGER':
        return isDark ? const Color(0xFF2563EB).withValues(alpha: 0.5) : const Color(0xFFBFDBFE);
      case 'SUPPORT':
        return isDark ? const Color(0xFF9333EA).withValues(alpha: 0.5) : const Color(0xFFE9D5FF);
      case 'ANALYST':
        return isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFFA7F3D0);
      case 'STORE_MANAGER':
        return isDark ? const Color(0xFF0D9488).withValues(alpha: 0.5) : const Color(0xFF99F6E4);
      default:
        return isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    }
  }

  Widget _buildRoleBadge(String rawRole, bool isRtl, bool isDark) {
    final role = _normalizeRole(rawRole);
    final hasPillBadge = role == 'SUPER_ADMIN' ||
        role == 'CONTENT_MANAGER' ||
        role == 'SUPPORT' ||
        role == 'ANALYST';

    if (!hasPillBadge) {
      return Text(
        rawRole,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          letterSpacing: 0.02,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: _getRoleBgColor(rawRole, isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getRoleBorderColor(rawRole, isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(rawRole),
            size: 13,
            color: _getRoleTextColor(rawRole, isDark),
          ),
          const SizedBox(width: 4),
          Text(
            _getRoleLabel(rawRole, isRtl),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _getRoleTextColor(rawRole, isDark),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '—';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('MMM d, yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  // --- Actions & Confirmation Dialogs ---
  Future<void> _toggleStatus(AdminUser admin, bool isRtl, bool isDark) async {
    final actionNameEn = admin.active ? 'deactivate' : 'activate';
    final actionNameAr = admin.active ? 'تعطيل' : 'تفعيل';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: admin.active ? const Color(0xFFD97706) : const Color(0xFF10B981),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRtl ? 'تأكيد تغيير الحالة' : 'Confirm Status Change',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من رغبتك في $actionNameAr حساب ${admin.fullName}؟'
              : 'Are you sure you want to $actionNameEn access for ${admin.fullName}?',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isRtl ? 'إلغاء' : 'Cancel',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: admin.active ? const Color(0xFFD97706) : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isRtl ? 'نعم، $actionNameAr' : 'Yes, $actionNameEn',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(adminUserRepositoryProvider.notifier).toggleAdminStatus(admin.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl ? 'تم تحديث الحالة بنجاح' : 'Status updated successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl ? 'فشل تحديث الحالة: $e' : 'Failed to update status: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAdmin(AdminUser admin, bool isRtl, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRtl ? 'حذف حساب المشرف؟' : 'Delete Staff Member?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من رغبتك في حذف حساب ${admin.fullName} نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to permanently remove ${admin.fullName} (${admin.email})? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isRtl ? 'إلغاء' : 'Cancel',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isRtl ? 'نعم، احذف نهائياً' : 'Yes, Delete Permanently',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(adminUserRepositoryProvider.notifier).deleteAdmin(admin.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl ? 'تم حذف المشرف بنجاح' : 'Admin user removed successfully.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl ? 'فشل الحذف: $e' : 'Failed to delete admin user: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showAddAdminModal(BuildContext context, bool isRtl, bool isDark) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    String selectedRole = 'CONTENT_MANAGER';
    bool showPassword = false;
    bool isSubmitting = false;
    String? submitError;

    String generateRandomPassword() {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%*';
      final rand = Random();
      final buffer = StringBuffer('Admin@');
      for (int i = 0; i < 6; i++) {
        buffer.write(chars[rand.nextInt(chars.length)]);
      }
      return buffer.toString();
    }

    passwordCtrl.text = generateRandomPassword();

    final roleOptions = [
      CustomSelectOption<String>(
        value: 'SUPER_ADMIN',
        labelEn: 'Super Administrator',
        labelAr: 'مشرف عام',
        icon: Icons.security_rounded,
      ),
      CustomSelectOption<String>(
        value: 'CONTENT_MANAGER',
        labelEn: 'Content Manager',
        labelAr: 'مدير المحتوى والعروض',
        icon: Icons.edit_note_rounded,
      ),
      CustomSelectOption<String>(
        value: 'SUPPORT',
        labelEn: 'Support Specialist',
        labelAr: 'أخصائي الدعم الفني',
        icon: Icons.support_agent_rounded,
      ),
      CustomSelectOption<String>(
        value: 'ANALYST',
        labelEn: 'Data Analyst',
        labelAr: 'محلل بيانات وتقارير',
        icon: Icons.insights_rounded,
      ),
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? 'تسجيل مشرف جديد' : 'Register New Staff Member',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRtl
                            ? 'إنشاء بيانات الدخول وتعيين الصلاحيات لمشرف ديل سبوت'
                            : 'Create credentials and assign role for new DealSpot administrator.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  splashRadius: 18,
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (submitError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  submitError!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Full Name Field
                      _buildFieldLabel(isRtl ? 'الاسم الكامل' : 'Full Name', true, isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: _buildInputDecoration(
                          hint: isRtl ? 'مثال: طارق الغامدي' : 'e.g. Tariq Al-Ghamdi',
                          icon: Icons.badge_outlined,
                          isDark: isDark,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 3) {
                            return isRtl
                                ? 'الاسم الكامل مطلوب (3 أحرف على الأقل).'
                                : 'Full name is required (at least 3 characters).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Official Work Email Field
                      _buildFieldLabel(isRtl ? 'البريد الإلكتروني المهني' : 'Official Work Email', true, isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          hint: 'staff@dealspot.com',
                          icon: Icons.mail_outline_rounded,
                          isDark: isDark,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isRtl ? 'البريد الإلكتروني مطلوب.' : 'Email is required.';
                          }
                          final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegExp.hasMatch(val.trim())) {
                            return isRtl
                                ? 'يرجى إدخال بريد إلكتروني صحيح.'
                                : 'Valid work email is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Assigned Role Selector
                      _buildFieldLabel(isRtl ? 'الدور والصلاحية' : 'Assigned Role', true, isDark),
                      const SizedBox(height: 6),
                      AppCustomSelect<String>(
                        options: roleOptions,
                        selectedValue: selectedRole,
                        placeholder: isRtl ? 'اختر الدور' : 'Select Role',
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Initial Password Field with Generate Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel(isRtl ? 'كلمة المرور الأولية' : 'Initial Password', true, isDark),
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                passwordCtrl.text = generateRandomPassword();
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.autorenew_rounded, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text(
                                    isRtl ? 'توليد كلمة مرور' : 'Generate Random',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 19,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 19,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setModalState(() => showPassword = !showPassword);
                            },
                          ),
                          hintText: '••••••••',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return isRtl
                                ? 'كلمة المرور يجب أن لا تقل عن 6 أحرف.'
                                : 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text(
                  isRtl ? 'إلغاء' : 'Cancel',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() != true) return;
                        setModalState(() {
                          isSubmitting = true;
                          submitError = null;
                        });

                        try {
                          final created = await ref.read(adminUserRepositoryProvider.notifier).createAdmin(
                                fullName: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                                role: selectedRole,
                              );

                          if (ctx.mounted) Navigator.pop(ctx);

                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (successCtx) => AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 26),
                                    const SizedBox(width: 10),
                                    Text(
                                      isRtl ? 'تم إنشاء الحساب بنجاح!' : 'Admin Created!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  isRtl
                                      ? 'تم إنشاء حساب إشرافي جديد للمستخدم ${created.fullName} (${created.email}).'
                                      : 'New staff account created for ${created.fullName} (${created.email}).',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(successCtx),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(isRtl ? 'حسناً' : 'OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() {
                            isSubmitting = false;
                            submitError = isRtl
                                ? 'تعذر إنشاء الحساب. قد يكون البريد مسجلاً مسبقاً.'
                                : 'Failed to create admin user. Email might already exist.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.how_to_reg_rounded, size: 18),
                label: Text(
                  isSubmitting
                      ? (isRtl ? 'جاري الحفظ...' : 'Saving...')
                      : (isRtl ? 'حفظ وتسجيل المشرف' : 'Save & Register Admin'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isRequired, bool isDark) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        size: 19,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final adminState = ref.watch(adminUserRepositoryProvider);
    final allAdmins = adminState.admins;
    final filteredAdmins = _getFilteredAdmins(allAdmins);

    // Stats calculations
    final totalCount = allAdmins.length;
    final activeCount = allAdmins.where((a) => a.active).length;
    final superAdminCount = allAdmins.where((a) => _normalizeRole(a.role) == 'SUPER_ADMIN').length;

    final roleFilterOptions = [
      CustomSelectOption<String>(
        value: 'ALL',
        labelEn: 'All Roles',
        labelAr: 'جميع الأدوار',
      ),
      CustomSelectOption<String>(
        value: 'SUPER_ADMIN',
        labelEn: 'Super Administrator',
        labelAr: 'مشرف عام',
        icon: Icons.security_rounded,
      ),
      CustomSelectOption<String>(
        value: 'CONTENT_MANAGER',
        labelEn: 'Content Manager',
        labelAr: 'مدير المحتوى والعروض',
        icon: Icons.edit_note_rounded,
      ),
      CustomSelectOption<String>(
        value: 'SUPPORT',
        labelEn: 'Support Specialist',
        labelAr: 'أخصائي الدعم الفني',
        icon: Icons.support_agent_rounded,
      ),
      CustomSelectOption<String>(
        value: 'ANALYST',
        labelEn: 'Data Analyst',
        labelAr: 'محلل بيانات وتقارير',
        icon: Icons.insights_rounded,
      ),
      CustomSelectOption<String>(
        value: 'STORE_MANAGER',
        labelEn: 'Store Manager',
        labelAr: 'مدير متجر',
        icon: Icons.storefront_rounded,
      ),
    ];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF10B981),
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Block
                    _buildHeader(context, isRtl, isDark),
                    const SizedBox(height: 20),

                    // 2. Stats Grid
                    _buildStatsGrid(totalCount, activeCount, superAdminCount, isRtl, isDark),
                    const SizedBox(height: 20),

                    // 3. Filters Toolbar
                    _buildFiltersToolbar(context, roleFilterOptions, isRtl, isDark),
                    const SizedBox(height: 20),

                    // 4. Content Area
                    if (adminState.isLoading && allAdmins.isEmpty) ...[
                      CrudLoadingWidget(
                        titleEn: 'Loading staff accounts...',
                        titleAr: 'جاري تحميل المشرفين...',
                        isRtl: isRtl,
                        isDark: isDark,
                      ),
                    ] else if (filteredAdmins.isEmpty) ...[
                      _buildEmptyState(isRtl, isDark, adminState.errorMessage),
                    ] else ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 960) {
                            return _buildDesktopTable(context, filteredAdmins, isRtl, isDark);
                          } else {
                            return _buildMobileCardList(context, filteredAdmins, isRtl, isDark);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Header ---
  Widget _buildHeader(BuildContext context, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final titleCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: isDark ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                  size: isMobile ? 22 : 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRtl ? 'إدارة فريق الإشراف والموظفين' : 'Admin Team & Staff Management',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isRtl
                  ? 'تسجيل وتعيين الأدوار وإدارة صلاحيات المشرفين على النظام.'
                  : 'Register, assign roles, and manage permissions for system administrators.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        );

        final addBtn = ElevatedButton.icon(
          onPressed: () => _showAddAdminModal(context, isRtl, isDark),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: Text(isRtl ? 'تسجيل مشرف جديد' : 'Register New Staff'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleCol,
              const SizedBox(height: 14),
              addBtn,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleCol),
            const SizedBox(width: 16),
            addBtn,
          ],
        );
      },
    );
  }

  // --- 2. Stats Grid ---
  Widget _buildStatsGrid(int totalCount, int activeCount, int superAdminCount, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final cards = [
          _buildStatCard(
            title: isRtl ? 'إجمالي المشرفين' : 'Total Staff',
            count: totalCount.toString(),
            icon: Icons.groups_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isRtl ? 'الحسابات النشطة' : 'Active Accounts',
            count: activeCount.toString(),
            icon: Icons.check_circle_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isRtl ? 'المشرفين العامين' : 'Super Admins',
            count: superAdminCount.toString(),
            icon: Icons.shield_rounded,
            iconBg: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFD97706),
            isDark: isDark,
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Filters Toolbar ---
  Widget _buildFiltersToolbar(
    BuildContext context,
    List<CustomSelectOption<String>> roleFilterOptions,
    bool isRtl,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 640;

          final searchInput = SizedBox(
            width: isMobile ? double.infinity : 360,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: isRtl ? 'ابحث بالاسم، البريد، أو الدور...' : 'Search by name, email, or role...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 17),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          );

          final roleDropdown = Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                isRtl ? 'تصفية بالدور:' : 'Role Filter:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: isMobile ? 1 : 0,
                child: SizedBox(
                  width: isMobile ? null : 190,
                  child: AppCustomSelect<String>(
                    options: roleFilterOptions,
                    selectedValue: _selectedRoleFilter,
                    placeholder: isRtl ? 'جميع الأدوار' : 'All Roles',
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRoleFilter = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchInput,
                const SizedBox(height: 12),
                roleDropdown,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              searchInput,
              roleDropdown,
            ],
          );
        },
      ),
    );
  }

  // --- 4. Desktop Data Table ---
  Widget _buildDesktopTable(
    BuildContext context,
    List<AdminUser> admins,
    bool isRtl,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 920),
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 24,
            headingRowHeight: 48,
            dataRowMaxHeight: 66,
            dataRowMinHeight: 58,
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
            columns: [
              DataColumn(
                label: Text(
                  isRtl ? 'المشرف' : 'STAFF MEMBER',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.04,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'الدور والصلاحيات' : 'ROLE & PERMISSIONS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.04,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'الحالة' : 'STATUS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.04,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  isRtl ? 'تاريخ التسجيل' : 'REGISTERED DATE',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.04,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              DataColumn(
                label: Align(
                  alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                  child: Text(
                    isRtl ? 'إجراءات' : 'ACTIONS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.04,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
            rows: admins.map((admin) {
              final initial = admin.fullName.isNotEmpty ? admin.fullName.trim()[0].toUpperCase() : 'U';
              final isSuper = _normalizeRole(admin.role) == 'SUPER_ADMIN';

              return DataRow(
                cells: [
                  // 1. Staff Member (Avatar + Name + Email)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSuper
                                ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB))
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFECFDF5)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSuper
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFF10B981).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSuper
                                  ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706))
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              admin.fullName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              admin.email,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Role Pill Badge
                  DataCell(
                    _buildRoleBadge(admin.role, isRtl, isDark),
                  ),

                  // 3. Status Button Pill
                  DataCell(
                    InkWell(
                      onTap: () => _toggleStatus(admin, isRtl, isDark),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: admin.active
                              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: admin.active
                                ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFFA7F3D0))
                                : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: admin.active ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              admin.active
                                  ? (isRtl ? 'مفعّل' : 'Active')
                                  : (isRtl ? 'معطّل' : 'Inactive'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: admin.active
                                    ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Registered Date
                  DataCell(
                    Text(
                      _formatDate(admin.createdAt),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),

                  // 5. Delete Action
                  DataCell(
                    Align(
                      alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        tooltip: isRtl ? 'حذف المشرف' : 'Delete admin',
                        splashRadius: 18,
                        hoverColor: const Color(0xFFFEE2E2),
                        onPressed: () => _deleteAdmin(admin, isRtl, isDark),
                      ),
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

  // --- 5. Mobile Cards List ---
  Widget _buildMobileCardList(
    BuildContext context,
    List<AdminUser> admins,
    bool isRtl,
    bool isDark,
  ) {
    return Column(
      children: admins.map((admin) {
        final initial = admin.fullName.isNotEmpty ? admin.fullName.trim()[0].toUpperCase() : 'U';
        final isSuper = _normalizeRole(admin.role) == 'SUPER_ADMIN';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSuper
                          ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFECFDF5)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSuper
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSuper
                            ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706))
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          admin.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    onPressed: () => _deleteAdmin(admin, isRtl, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Role Badge
                  _buildRoleBadge(admin.role, isRtl, isDark),

                  // Status Button
                  InkWell(
                    onTap: () => _toggleStatus(admin, isRtl, isDark),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: admin.active
                            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: admin.active
                              ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFFA7F3D0))
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: admin.active ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            admin.active
                                ? (isRtl ? 'مفعّل' : 'Active')
                                : (isRtl ? 'معطّل' : 'Inactive'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: admin.active
                                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (admin.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${isRtl ? "تاريخ التسجيل: " : "Registered: "}${_formatDate(admin.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 6. Empty State & Quick Auth Modal ---
  void _showQuickAdminLoginModal(BuildContext context, bool isRtl, bool isDark) {
    final emailCtrl = TextEditingController(text: 'admin@dealspot.com');
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    bool obscurePass = true;
    String? authError;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isRtl ? 'تسجيل دخول المشرف' : 'Admin Re-Authentication',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isRtl
                      ? 'يرجى تسجيل الدخول بحساب المشرف لتحميل وإدارة طاقم العمل.'
                      : 'Please authenticate with an admin account to view and manage staff.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (authError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authError!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      hint: 'admin@dealspot.com',
                      icon: Icons.mail_outline_rounded,
                      isDark: isDark,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 19,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        onPressed: () => setModalState(() => obscurePass = !obscurePass),
                      ),
                      hintText: '••••••••',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(modalCtx),
              child: Text(isRtl ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState?.validate() != true) return;
                      setModalState(() {
                        isSubmitting = true;
                        authError = null;
                      });
                      final ok = await ref.read(authProvider.notifier).adminLogin(
                            emailCtrl.text.trim(),
                            passCtrl.text,
                          );
                      if (ok) {
                        if (modalCtx.mounted) Navigator.pop(modalCtx);
                        await _loadData();
                      } else {
                        setModalState(() {
                          isSubmitting = false;
                          authError = isRtl
                              ? 'فشل تسجيل الدخول. تحقق من البريد وكلمة المرور.'
                              : 'Invalid admin credentials or server unreachable.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isRtl ? 'تسجيل الدخول والتحديث' : 'Log In & Load'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isRtl, bool isDark, [String? errorMessage]) {
    final hasError = errorMessage != null && errorMessage.isNotEmpty;
    final is401 = errorMessage == '401_UNAUTHORIZED' ||
        (errorMessage?.contains('401') ?? false) ||
        (errorMessage?.toLowerCase().contains('unauthorized') ?? false);
    final isUnreachable = errorMessage == 'SERVER_UNREACHABLE' ||
        (errorMessage?.contains('connect') ?? false);

    IconData stateIcon;
    String stateTitle;
    String stateDescription;

    if (is401) {
      stateIcon = Icons.lock_clock_rounded;
      stateTitle = isRtl ? 'انتهت صلاحية جلسة المشرف' : 'Admin Authentication Required';
      stateDescription = isRtl
          ? 'انتهت صلاحية رمز الدخول أو أنك غير مسجل كمسؤول. يرجى تسجيل الدخول كمشرف لتحميل وإدارة الطاقم.'
          : 'Your admin session has expired or requires authentication to view and manage staff.';
    } else if (isUnreachable) {
      stateIcon = Icons.wifi_off_rounded;
      stateTitle = isRtl ? 'تعذر الاتصال بالخادم' : 'Backend Server Unreachable';
      stateDescription = isRtl
          ? 'تأكد من تشغيل خادم الربط (Spring Boot) والاتصال بنفس الشبكة.'
          : 'Please check your connection or verify that the Spring Boot backend server is running.';
    } else if (hasError) {
      stateIcon = Icons.error_outline_rounded;
      stateTitle = isRtl ? 'تعذر تحميل بيانات المشرفين' : 'Failed to Load Staff Accounts';
      stateDescription = errorMessage;
    } else {
      stateIcon = Icons.manage_accounts_outlined;
      stateTitle = isRtl ? 'لم يتم العثور على مشرفين' : 'No Admin Accounts Found';
      stateDescription = isRtl
          ? 'جرب تغيير معايير البحث أو قم بتسجيل مشرف جديد.'
          : 'Try adjusting your search criteria or register a new staff member.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            stateIcon,
            size: 56,
            color: (hasError || is401)
                ? const Color(0xFFEF4444)
                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            stateTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              stateDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: (hasError || is401)
                    ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (is401) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showQuickAdminLoginModal(context, isRtl, isDark),
                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                  label: Text(isRtl ? 'تسجيل الدخول كمشرف' : 'Log In as Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(isRtl ? 'إعادة المحاولة' : 'Retry'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ] else if (hasError) ...[
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isRtl ? 'إعادة المحاولة' : 'Retry Loading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _showAddAdminModal(context, isRtl, isDark),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(isRtl ? 'تسجيل أول مشرف' : 'Register First Staff Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
