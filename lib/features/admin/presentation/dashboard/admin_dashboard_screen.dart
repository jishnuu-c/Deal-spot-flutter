import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/models.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/utils/translation_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _getUserRoleLabel(String role, bool isRtl) {
    final r = role.toUpperCase();
    if (isRtl) {
      if (r == 'SUPER_ADMIN') return 'المدير العام';
      if (r == 'STORE_MANAGER') return 'مدير المتجر';
      return 'المشرف';
    } else {
      if (r == 'SUPER_ADMIN') return 'Super Administrator';
      if (r == 'STORE_MANAGER') return 'Store Manager';
      return 'Administrator';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final adminUser = authState.currentAdmin;
    final role = (adminUser?.role ?? 'SUPER_ADMIN').toUpperCase();
    final userRoleLabel = _getUserRoleLabel(role, isRtl);
    final fullName = adminUser?.fullName ?? '';
    final displayName = fullName.isNotEmpty ? fullName : userRoleLabel;

    // All 12 Modules exactly matching Angular dashboard.component.html
    final modules = <_ModuleCardData>[
      // 1. Stores
      _ModuleCardData(
        route: '/admin/stores',
        icon: Icons.store_rounded,
        titleEn: 'Retail Stores',
        titleAr: 'المتاجر والشركاء',
        descEn: 'Manage verified partner stores, CR numbers, branches, and statuses.',
        descAr: 'إدارة المتاجر الشريكة الموثقة، السجلات التجارية، الفروع، والحالات.',
        color: const Color(0xFF16A34A),
        bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFDCFCE7),
      ),
      // 2. Brands
      _ModuleCardData(
        route: '/admin/brands',
        icon: Icons.loyalty_rounded,
        titleEn: 'Partner Brands',
        titleAr: 'العلامات التجارية',
        descEn: 'Configure official brand logos, search tags, website links, and profiles.',
        descAr: 'إدارة شعارات الماركات، وسوم البحث، الروابط الرسمية، والملفات التعريفية.',
        color: const Color(0xFF7C3AED),
        bgColor: isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.35) : const Color(0xFFEDE9FE),
      ),
      // 3. Products
      _ModuleCardData(
        route: '/admin/products',
        icon: Icons.shopping_bag_rounded,
        titleEn: 'Product Catalog',
        titleAr: 'كتالوج المنتجات',
        descEn: 'Manage product dimensions, barcode specifications, and SKU items.',
        descAr: 'إدارة مواصفات وأبعاد المنتجات، أرقام الباركود، ووحدات التخزين.',
        color: const Color(0xFF0D9488),
        bgColor: isDark ? const Color(0xFF042F2E).withValues(alpha: 0.35) : const Color(0xFFCCFBF1),
      ),
      // 4. Offers
      _ModuleCardData(
        route: '/admin/offers',
        icon: Icons.local_offer_rounded,
        titleEn: 'Promotions & Deals',
        titleAr: 'العروض والتخفيضات',
        descEn: 'Manage active discounts, flash sales, featured items, and BOGO deals.',
        descAr: 'إدارة الخصومات النشطة، صفقات الفلاش، العروض المميزة وتخفيضات BOGO.',
        color: const Color(0xFF2563EB),
        bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFDBEAFE),
      ),
      // 5. Flyers
      _ModuleCardData(
        route: '/admin/flyers',
        icon: Icons.menu_book_rounded,
        titleEn: 'Brochures & Flyers',
        titleAr: 'المجلات والمنشورات',
        descEn: 'Upload and manage scanned promotional flyers, pages, and validity dates.',
        descAr: 'رفع وإدارة منشورات العروض الترويجية، الصفحات، وفترات الصلاحية.',
        color: const Color(0xFFD97706),
        bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
      ),
      // 6. Coupons
      _ModuleCardData(
        route: '/admin/coupons',
        icon: Icons.confirmation_number_rounded,
        titleEn: 'Promo Coupons',
        titleAr: 'كوبونات الخصم',
        descEn: 'Create discount vouchers, usage thresholds, and expiry state controls.',
        descAr: 'إنشاء قسائم التخفيض، حدود الاستخدام، والتحكم بحالات الانتهاء.',
        color: const Color(0xFFEA580C),
        bgColor: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFEDD5),
      ),
      // 7. Partner Requests
      _ModuleCardData(
        route: '/admin/partner-requests',
        icon: Icons.handshake_rounded,
        titleEn: 'Partner Requests',
        titleAr: 'طلبات الشراكة',
        descEn: 'Review merchant applications, documents, contact details, and approvals.',
        descAr: 'مراجعة طلبات انضمام التجار، المستندات، بيانات التواصل، والموافقات.',
        color: const Color(0xFFB45309),
        bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
      ),
      // 8. Notifications
      _ModuleCardData(
        route: '/admin/notifications',
        icon: Icons.notifications_rounded,
        titleEn: 'Broadcast Alerts',
        titleAr: 'إرسال الإشعارات',
        descEn: 'Send SMS, Email, and in-app push promotional announcements.',
        descAr: 'إرسال الرسائل النصية، والبريد الإلكتروني، وتنبيهات التطبيق للمستخدمين.',
        color: const Color(0xFFDC2626),
        bgColor: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEE2E2),
      ),
      // 9. Cities
      _ModuleCardData(
        route: '/admin/cities',
        icon: Icons.place_rounded,
        titleEn: 'Cities & Locations',
        titleAr: 'المدن والمناطق',
        descEn: 'Configure operational coverage areas, provinces, and city coordinates.',
        descAr: 'إدارة مناطق التغطية الجغرافية، المحافظات، وإحداثيات المدن.',
        color: const Color(0xFF0891B2),
        bgColor: isDark ? const Color(0xFF164E63).withValues(alpha: 0.35) : const Color(0xFFCFFAFE),
      ),
      // 10. Categories
      _ModuleCardData(
        route: '/admin/categories',
        icon: Icons.category_rounded,
        titleEn: 'Departments & Categories',
        titleAr: 'الأقسام والتصنيفات',
        descEn: 'Structure catalog taxonomy, category icons, display order, and hierarchy.',
        descAr: 'تنظيم التصنيفات، أيقونات الأقسام، ترتيب العرض، والتسلسل الهرمي.',
        color: const Color(0xFF4F46E5),
        bgColor: isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFE0E7FF),
      ),
      // 11. Staff & Admins
      _ModuleCardData(
        route: '/admin/users',
        icon: Icons.people_rounded,
        titleEn: 'Staff & Admins',
        titleAr: 'المشرفين والموظفين',
        descEn: 'Manage user roles, store manager accounts, and administrative access.',
        descAr: 'إدارة أدوار المستخدمين، حسابات مدراء المتاجر، وصلاحيات الوصول.',
        color: const Color(0xFF475569),
        bgColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
      ),
      // 12. Audit Logs
      _ModuleCardData(
        route: '/admin/audit-logs',
        icon: Icons.history_edu_rounded,
        titleEn: 'Audit & History Logs',
        titleAr: 'سجل العمليات والتدقيق',
        descEn: 'Track administrative operations, timestamps, and audit history.',
        descAr: 'تتبع العمليات الإدارية، التوقيتات، وسجلات التعديلات في النظام.',
        color: const Color(0xFF4B5563),
        bgColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.35) : const Color(0xFFF3F4F6),
      ),
    ];

    final isWide = MediaQuery.of(context).size.width >= 768;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 28 : 16,
            vertical: isWide ? 28 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header (.dash-welcome)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 28 : 18,
                  vertical: isWide ? 24 : 18,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // .dash-welcome-text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'مرحباً، $displayName' : 'Welcome, $displayName',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isRtl
                                      ? 'لوحة التحكم ومركز الإدارة السريعة للكتالوجات، والشركاء التجاريين، والعروض، وعمليات النظام.'
                                      : 'Control panel and quick management center for catalogs, retail partners, promotions, and system operations.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // .dash-welcome-badge -> .role-badge
                          _buildRoleBadge(userRoleLabel, isDark),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  isRtl ? 'مرحباً، $displayName' : 'Welcome, $displayName',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildRoleBadge(userRoleLabel, isDark),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isRtl
                                ? 'لوحة التحكم ومركز الإدارة السريعة للكتالوجات، والشركاء التجاريين، والعروض، وعمليات النظام.'
                                : 'Control panel and quick management center for catalogs, retail partners, promotions, and system operations.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 28),

              // 2. Main Management Modules Grid (.modules-section)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // .section-header
                  Row(
                    children: [
                      const Icon(Icons.apps_rounded, color: Color(0xFF16A34A), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isRtl ? 'أقسام وكتالوجات النظام' : 'System Modules & Catalogs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // .modules-grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final int crossAxisCount = width >= 1100
                          ? 4
                          : (width >= 800 ? 3 : (width >= 540 ? 2 : 1));
                      final double childAspectRatio = width >= 1100
                          ? 2.1
                          : (width >= 800 ? 2.1 : (width >= 540 ? 2.2 : 3.0));

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: modules.length,
                        itemBuilder: (context, index) {
                          final m = modules[index];
                          return _buildModuleCard(
                            context: context,
                            data: m,
                            isRtl: isRtl,
                            isDark: isDark,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. Fast Creation Actions Bar (.quick-creation-panel.card)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 28 : 18,
                  vertical: isWide ? 24 : 18,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // .quick-header
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Color(0xFFEAB308), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isRtl ? 'إجراءات سريعة' : 'Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // .quick-buttons-row
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Add New Offer (.btn-offer)
                        _buildQuickActionBtn(
                          context: context,
                          route: '/admin/offers',
                          icon: Icons.add_circle_rounded,
                          label: isRtl ? 'إضافة عرض جديد' : 'Add New Offer',
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderColor: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        ),
                        // Upload New Flyer (.btn-flyer)
                        _buildQuickActionBtn(
                          context: context,
                          route: '/admin/flyers',
                          icon: Icons.upload_file_rounded,
                          label: isRtl ? 'رفع منشور جديد' : 'Upload New Flyer',
                          color: const Color(0xFFB45309),
                          bgColor: const Color(0xFFEAB308).withValues(alpha: isDark ? 0.2 : 0.15),
                          borderColor: const Color(0xFFEAB308).withValues(alpha: 0.3),
                        ),
                        // Add New Product (.btn-product)
                        _buildQuickActionBtn(
                          context: context,
                          route: '/admin/products',
                          icon: Icons.post_add_rounded,
                          label: isRtl ? 'إضافة منتج جديد' : 'Add New Product',
                          color: const Color(0xFF0F766E),
                          bgColor: const Color(0xFF14B8A6).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderColor: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                        ),
                        // Create Coupon (.btn-coupon)
                        _buildQuickActionBtn(
                          context: context,
                          route: '/admin/coupons',
                          icon: Icons.confirmation_number_rounded,
                          label: isRtl ? 'إنشاء كوبون' : 'Create Coupon',
                          color: const Color(0xFFC2410C),
                          bgColor: const Color(0xFFF97316).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderColor: const Color(0xFFF97316).withValues(alpha: 0.25),
                        ),
                        // Broadcast Notification (.btn-notif)
                        _buildQuickActionBtn(
                          context: context,
                          route: '/admin/notifications',
                          icon: Icons.campaign_rounded,
                          label: isRtl ? 'إرسال إشعار' : 'Broadcast Notification',
                          color: const Color(0xFFEF4444),
                          bgColor: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderColor: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Role Badge (.role-badge)
  Widget _buildRoleBadge(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF16A34A),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  // Module Card (.module-card.card)
  Widget _buildModuleCard({
    required BuildContext context,
    required _ModuleCardData data,
    required bool isRtl,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(data.route),
          hoverColor: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // .module-icon-wrapper
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: data.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 26),
                ),
                const SizedBox(width: 16),

                // .module-details
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? data.titleAr : data.titleEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isRtl ? data.descAr : data.descEn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // .arrow
                Icon(
                  isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Quick Action Button (.quick-action-btn)
  Widget _buildQuickActionBtn({
    required BuildContext context,
    required String route,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCardData {
  final String route;
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String descEn;
  final String descAr;
  final Color color;
  final Color bgColor;

  const _ModuleCardData({
    required this.route,
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.descEn,
    required this.descAr,
    required this.color,
    required this.bgColor,
  });
}
