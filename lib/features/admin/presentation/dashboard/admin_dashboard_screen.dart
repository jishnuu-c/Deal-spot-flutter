import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/audit_log.dart';
import '../../../../models/partner_request.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/flyer_repository.dart';
import '../../../../core/services/audit_log_repository.dart';
import '../../../../core/services/partner_request_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/services/brand_repository.dart';
import '../../../../core/utils/translation_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      ref.read(storeRepositoryProvider.notifier).fetchStores(),
      ref.read(offerRepositoryProvider.notifier).fetchOffers(),
      ref.read(offerRepositoryProvider.notifier).fetchSavedOffers(),
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers(),
      ref.read(partnerRequestRepositoryProvider.notifier).fetchRequests(),
      ref.read(cityRepositoryProvider.notifier).fetchCities(),
      ref.read(categoryRepositoryProvider.notifier).fetchCategories(),
      ref.read(brandRepositoryProvider.notifier).fetchBrands(),
    ]);
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Real live counts from repositories
    final storeState = ref.watch(storeRepositoryProvider);
    final offerState = ref.watch(offerRepositoryProvider);
    final flyerState = ref.watch(flyerRepositoryProvider);
    final partnerState = ref.watch(partnerRequestRepositoryProvider);
    final auditLogs = ref.watch(auditLogRepositoryProvider);

    final storesCount = storeState.stores.length;
    final offersCount = offerState.offers.length;
    final flyersCount = flyerState.flyers.length;
    final savesCount = offerState.savedOfferIds.length;
    final pendingPartnerCount = partnerState.requests
        .where((r) => r.status == PartnerRequestStatus.PENDING)
        .length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF16A34A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Welcome Section Header (Exact Angular copy)
                _buildWelcomeHeader(isRtl, isDark),
                const SizedBox(height: 20),

                // Pending Partner Requests Alert Banner if any
                if (pendingPartnerCount > 0) ...[
                  _buildPendingPartnerBanner(context, pendingPartnerCount, isRtl, isDark),
                  const SizedBox(height: 20),
                ],

                // 2. Stats Grid (4 Cards: Stores, Offers, Flyers, Saves)
                _buildStatsGrid(
                  context: context,
                  isRtl: isRtl,
                  isDark: isDark,
                  storesCount: storesCount,
                  offersCount: offersCount,
                  flyersCount: flyersCount,
                  savesCount: savesCount,
                ),
                const SizedBox(height: 28),

                // 3. Double Column Workspace (Quick Catalog Management & Recent Modifications)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 960;
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 10,
                            child: _buildQuickManagementPanel(
                              context,
                              isRtl,
                              isDark,
                              pendingPartnerCount: pendingPartnerCount,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 12,
                            child: _buildRecentModificationsPanel(context, auditLogs, isRtl, isDark),
                          ),
                        ],
                      );
                    } else {
                      // Mobile & Tablet Portrait: Stacked Column
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildQuickManagementPanel(
                            context,
                            isRtl,
                            isDark,
                            pendingPartnerCount: pendingPartnerCount,
                          ),
                          const SizedBox(height: 24),
                          _buildRecentModificationsPanel(context, auditLogs, isRtl, isDark),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pending Partner Banner
  Widget _buildPendingPartnerBanner(
      BuildContext context, int pendingCount, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.4 : 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isRtl ? 'طلبات شراكة بانتظار المراجعة' : 'Pending Partner Requests',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isRtl
                      ? 'يوجد لديك $pendingCount طلب انضمام جديد من التجار بانتظار مراجعة السجل التجاري والاعتماد.'
                      : 'You have $pendingCount new merchant partner requests awaiting CR verification and store provisioning.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () => context.go('/admin/partner-requests'),
            child: Text(
              isRtl ? 'مراجعة الطلبات' : 'Review Requests',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // Welcome Header
  Widget _buildWelcomeHeader(bool isRtl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRtl ? 'مرحباً، المشرف' : 'Welcome, Administrator',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isRtl
              ? 'إليك نظرة عامة على الكتالوجات النشطة، الشركاء، إحصائيات الخصومات وسجلات التعديل.'
              : 'Here is an overview of active catalogs, retail partners, discount statistics, and audit trails.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 4-Card Stats Grid
  Widget _buildStatsGrid({
    required BuildContext context,
    required bool isRtl,
    required bool isDark,
    required int storesCount,
    required int offersCount,
    required int flyersCount,
    required int savesCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 900 ? 4 : (width >= 480 ? 2 : 2);
        final double childAspectRatio = width >= 900 ? 1.45 : (width >= 480 ? 1.6 : 1.35);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              context: context,
              icon: Icons.storefront_outlined,
              label: isRtl ? 'المتاجر' : 'Retail Stores',
              count: storesCount.toString(),
              color: const Color(0xFF16A34A),
              bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFDCFCE7),
              route: '/admin/stores',
              isDark: isDark,
            ),
            _buildStatCard(
              context: context,
              icon: Icons.local_offer_outlined,
              label: isRtl ? 'العروض النشطة' : 'Active Offers',
              count: offersCount.toString(),
              color: const Color(0xFF2563EB),
              bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFDBEAFE),
              route: '/admin/offers',
              isDark: isDark,
            ),
            _buildStatCard(
              context: context,
              icon: Icons.menu_book_outlined,
              label: isRtl ? 'منشورات الكتالوج' : 'Catalog Flyers',
              count: flyersCount.toString(),
              color: const Color(0xFFD97706),
              bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
              route: '/admin/flyers',
              isDark: isDark,
            ),
            _buildStatCard(
              context: context,
              icon: Icons.bookmark_border_rounded,
              label: isRtl ? 'حفظ العروض' : 'Offer Saves',
              count: savesCount.toString(),
              color: const Color(0xFFDC2626),
              bgColor: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEE2E2),
              route: '/saved-offers',
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  // Single Stat Card
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    required Color bgColor,
    required String route,
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Left Column: Quick Catalog Management Panel
  Widget _buildQuickManagementPanel(
    BuildContext context,
    bool isRtl,
    bool isDark, {
    int pendingPartnerCount = 0,
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFF16A34A), size: 22),
                const SizedBox(width: 10),
                Text(
                  isRtl ? 'إدارة الكتالوج السريعة' : 'Quick Catalog Management',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          // Panel Body - Shortcuts List
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildShortcutItem(
                  context: context,
                  route: '/admin/partner-requests',
                  icon: Icons.handshake_outlined,
                  title: isRtl ? 'طلبات الشراكة' : 'Partner Applications',
                  subtitle: isRtl
                      ? 'مراجعة طلبات الانضمام واعتماد المتاجر والتحقق من السجل التجاري.'
                      : 'Review merchant partner requests, verify CR, and provision stores.',
                  isDark: isDark,
                  isRtl: isRtl,
                  badgeCount: pendingPartnerCount,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/cities',
                  icon: Icons.location_city_outlined,
                  title: isRtl ? 'إدارة المدن والمناطق' : 'Cities & Regions',
                  subtitle: isRtl
                      ? 'إدارة مناطق التغطية والإحداثيات الجغرافية ورموز المناطق.'
                      : 'Manage coverage zones, geo-coordinates and region codes.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/categories',
                  icon: Icons.category_outlined,
                  title: isRtl ? 'إدارة الفئات والأقسام' : 'Categories & Departments',
                  subtitle: isRtl
                      ? 'تنظيم الأقسام الرئيسية والفرعية وترتيب الظهور والأيقونات.'
                      : 'Organize parent and subcategories, sort orders, and icons.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/stores',
                  icon: Icons.storefront_outlined,
                  title: isRtl ? 'إدارة المتاجر' : 'Manage Retailers',
                  subtitle: isRtl
                      ? 'إعداد الأرقام الضريبية والسجل التجاري والشعارات وحالة التحقق.'
                      : 'Configure VAT numbers, CR, logos, and verification status.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/brands',
                  icon: Icons.loyalty_outlined,
                  title: isRtl ? 'الماركات الشريكة' : 'Brand Partners',
                  subtitle: isRtl
                      ? 'إعداد أسماء الماركات والشعارات وعلامات البحث والحالة.'
                      : 'Configure brand names, logos, search tags, and status.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/products',
                  icon: Icons.shopping_bag_outlined,
                  title: isRtl ? 'كتالوج المنتجات' : 'Product Catalog',
                  subtitle: isRtl
                      ? 'إدارة أبعاد المنتجات وبيانات الماركة والباركود والرموز.'
                      : 'Manage product dimensions, brand details, barcodes, and SKUs.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/offers',
                  icon: Icons.local_offer_outlined,
                  title: isRtl ? 'العروض الترويجية' : 'Active Promotions',
                  subtitle: isRtl
                      ? 'إضافة عروض مميزة، عروض فلاش، وعروض مجانية مع نسب تلقائية.'
                      : 'Add featured, flash, and BOGO deals with automatic percentages.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/flyers',
                  icon: Icons.menu_book_outlined,
                  title: isRtl ? 'المنشورات والكتالوجات' : 'Brochures & Flyers',
                  subtitle: isRtl
                      ? 'إعداد فترات صلاحية المنشورات وصفحات الكتالوج الممسوحة.'
                      : 'Configure flyer validity periods and scanned flyer pages.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
                const SizedBox(height: 10),
                _buildShortcutItem(
                  context: context,
                  route: '/admin/coupons',
                  icon: Icons.confirmation_number_outlined,
                  title: isRtl ? 'أكواد الكوبونات' : 'Coupon Codes',
                  subtitle: isRtl
                      ? 'إدارة قيم الخصم وحدود الاستخدام وحالات الصلاحية.'
                      : 'Manage discount values, usage thresholds, and validity states.',
                  isDark: isDark,
                  isRtl: isRtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Single Shortcut Item Card
  Widget _buildShortcutItem({
    required BuildContext context,
    required String route,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isRtl,
    int badgeCount = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badgeCount.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isRtl ? Icons.chevron_left : Icons.chevron_right,
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

  // Right Column: Recent Modifications Panel
  Widget _buildRecentModificationsPanel(
    BuildContext context,
    List<AuditLog> auditLogs,
    bool isRtl,
    bool isDark,
  ) {
    final recentLogs = auditLogs.take(6).toList();

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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu, color: Color(0xFF16A34A), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isRtl ? 'التعديلات الأخيرة' : 'Recent Modifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/admin/audit-logs'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRtl ? 'عرض السجل الكامل' : 'View All',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isRtl ? Icons.chevron_left : Icons.chevron_right,
                        size: 14,
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          // Panel Body - Audit Timeline or Empty State
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: recentLogs.isEmpty
                ? _buildEmptyAuditState(isRtl, isDark)
                : _buildAuditTimeline(recentLogs, isRtl, isDark),
          ),
        ],
      ),
    );
  }

  // Audit Timeline
  Widget _buildAuditTimeline(List<AuditLog> logs, bool isRtl, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final log = logs[index];
        final actionLower = log.action.toLowerCase();
        
        Color markerColor;
        Color badgeBg;
        Color badgeText;

        if (actionLower == 'create') {
          markerColor = const Color(0xFF16A34A);
          badgeBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7);
          badgeText = const Color(0xFF16A34A);
        } else if (actionLower == 'update') {
          markerColor = const Color(0xFF2563EB);
          badgeBg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFDBEAFE);
          badgeText = const Color(0xFF2563EB);
        } else if (actionLower == 'delete') {
          markerColor = const Color(0xFFDC2626);
          badgeBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2);
          badgeText = const Color(0xFFDC2626);
        } else {
          markerColor = const Color(0xFFD97706);
          badgeBg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7);
          badgeText = const Color(0xFFD97706);
        }

        // Time display
        String timeDisplay = log.createdAt;
        if (timeDisplay.contains('T')) {
          final parts = timeDisplay.split('T');
          if (parts.length > 1) {
            timeDisplay = parts[1].replaceAll('Z', '');
            if (timeDisplay.length > 8) {
              timeDisplay = timeDisplay.substring(0, 8);
            }
          }
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline vertical track with circular marker
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Timeline Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row: Action badge, Entity ID, and Date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.action.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: badgeText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${log.entityType.toUpperCase()} (ID: ${log.entityId})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          timeDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Performer info
                    Text(
                      isRtl
                          ? 'بواسطة المشرف ID: ${log.performedBy} • IP: ${log.ipAddress ?? "N/A"}'
                          : 'Performed by User ID: ${log.performedBy} • IP: ${log.ipAddress ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),

                    // Payload json box
                    if (log.payload != null && log.payload!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          jsonEncode(log.payload),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Empty State for Audits
  Widget _buildEmptyAuditState(bool isRtl, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 44,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              isRtl
                  ? 'لا توجد تعديلات مسجلة في سجلات النظام حتى الآن.'
                  : 'No changes recorded in the system logs yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
