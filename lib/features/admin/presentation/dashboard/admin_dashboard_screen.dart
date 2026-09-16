import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../models/models.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/flyer_repository.dart';
import '../../../../core/services/coupon_repository.dart';
import '../../../../core/services/partner_request_repository.dart';
import '../../../../core/services/audit_log_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../core/widgets/app_network_image.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = true;
  Store? _storeInfo;

  // Store Manager Metrics
  int _storeOffersCount = 0;
  int _storeFlyersCount = 0;
  int _storeBranchesCount = 0;
  int _storeFollowersCount = 0;
  int _storeCouponsCount = 0;

  // Super Admin Platform Metrics
  int _totalStoresCount = 0;
  int _totalOffersCount = 0;
  int _totalFlyersCount = 0;
  int _pendingPartnerRequestsCount = 0;
  int _totalCouponsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final authState = ref.read(authProvider);
    final adminUser = authState.currentAdmin;
    final isStoreManager = authState.isStoreManager;
    final storeId = adminUser?.storeId;

    if (isStoreManager && storeId != null) {
      await _loadStoreManagerData(storeId);
    } else {
      await _loadSuperAdminData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStoreManagerData(int storeId) async {
    try {
      // 1. Fetch Store Profile
      final storeNotifier = ref.read(storeRepositoryProvider.notifier);
      final store = await storeNotifier.fetchStoreById(storeId);
      _storeInfo = store;

      // 2. Fetch Branches count
      final branches = await storeNotifier.fetchBranchesForStore(storeId);
      _storeBranchesCount = branches.length;

      // 3. Fetch Offers count
      final offerNotifier = ref.read(offerRepositoryProvider.notifier);
      await offerNotifier.fetchOffers(storeId: storeId);
      final offers = ref.read(offerRepositoryProvider).offers.where((o) => o.storeId == storeId).toList();
      _storeOffersCount = offers.length;

      // 4. Fetch Flyers count
      final flyerNotifier = ref.read(flyerRepositoryProvider.notifier);
      await flyerNotifier.fetchFlyers(storeId: storeId);
      final flyers = ref.read(flyerRepositoryProvider).flyers.where((f) => f.storeId == storeId).toList();
      _storeFlyersCount = flyers.length;

      // 5. Followers count
      _storeFollowersCount = store?.followersCount ?? 0;

      // 6. Coupons count
      final couponNotifier = ref.read(couponRepositoryProvider.notifier);
      await couponNotifier.fetchCoupons(storeId: storeId);
      final coupons = ref.read(couponRepositoryProvider).where((c) => c.storeId == storeId).toList();
      _storeCouponsCount = coupons.length;
    } catch (_) {}
  }

  Future<void> _loadSuperAdminData() async {
    try {
      // 1. Stores
      final storeNotifier = ref.read(storeRepositoryProvider.notifier);
      await storeNotifier.fetchStores();
      _totalStoresCount = ref.read(storeRepositoryProvider).stores.length;

      // 2. Offers
      final offerNotifier = ref.read(offerRepositoryProvider.notifier);
      await offerNotifier.fetchOffers();
      _totalOffersCount = ref.read(offerRepositoryProvider).offers.length;

      // 3. Flyers
      final flyerNotifier = ref.read(flyerRepositoryProvider.notifier);
      await flyerNotifier.fetchFlyers();
      _totalFlyersCount = ref.read(flyerRepositoryProvider).flyers.length;

      // 4. Partner Requests
      final partnerNotifier = ref.read(partnerRequestRepositoryProvider.notifier);
      await partnerNotifier.fetchRequests();
      final allReqs = ref.read(partnerRequestRepositoryProvider).requests;
      _pendingPartnerRequestsCount = allReqs.where((r) => r.status == PartnerRequestStatus.PENDING).length;

      // 5. Coupons
      final couponNotifier = ref.read(couponRepositoryProvider.notifier);
      await couponNotifier.fetchCoupons();
      _totalCouponsCount = ref.read(couponRepositoryProvider).length;

      // 6. Recent Audit Activities
      final auditNotifier = ref.read(auditLogRepositoryProvider.notifier);
      await auditNotifier.fetchRecentActivities();
    } catch (_) {}
  }

  String _getUserRoleLabel(String role, bool isRtl) {
    final r = role.toUpperCase();
    if (isRtl) {
      if (r == 'SUPER_ADMIN') return 'المدير العام (Super Admin)';
      if (r == 'STORE_MANAGER') return 'مدير المتجر (Store Manager)';
      if (r == 'CONTENT_MANAGER') return 'مدير المحتوى (Content Manager)';
      return 'المشرف';
    } else {
      if (r == 'SUPER_ADMIN') return 'Super Administrator';
      if (r == 'STORE_MANAGER') return 'Store Manager';
      if (r == 'CONTENT_MANAGER') return 'Content Manager';
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
    final isStoreManager = authState.isStoreManager;
    final userRoleLabel = _getUserRoleLabel(role, isRtl);
    final fullName = adminUser?.fullName ?? '';
    final displayName = fullName.isNotEmpty ? fullName : userRoleLabel;
    final storeId = adminUser?.storeId;

    final isWide = MediaQuery.of(context).size.width >= 768;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF10B981),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 28 : 16,
              vertical: isWide ? 28 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Welcome Banner (.dash-welcome)
                _buildWelcomeHeader(
                  displayName: displayName,
                  userRoleLabel: userRoleLabel,
                  isStoreManager: isStoreManager,
                  isRtl: isRtl,
                  isDark: isDark,
                  isWide: isWide,
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 12),
                  const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                // =========================================================
                // 2. STORE MANAGER DASHBOARD VIEW
                // =========================================================
                if (isStoreManager) ...[
                  // Store Profile Hero Card
                  if (_storeInfo != null)
                    _buildStoreHeroCard(
                      store: _storeInfo!,
                      isRtl: isRtl,
                      isDark: isDark,
                      isWide: isWide,
                    ),
                  if (_storeInfo != null) const SizedBox(height: 22),

                  // Store Live Metrics Strip (5 pills)
                  _buildStoreStatsStrip(
                    isRtl: isRtl,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // Store Modules Grid
                  _buildStoreModulesGrid(
                    storeId: storeId,
                    isRtl: isRtl,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // Store Quick Creation Actions
                  _buildStoreQuickActions(
                    storeId: storeId,
                    isRtl: isRtl,
                    isDark: isDark,
                    isWide: isWide,
                  ),
                ]

                // =========================================================
                // 3. SUPER ADMIN DASHBOARD VIEW
                // =========================================================
                else ...[
                  // System Stats Overview Grid (5 stat cards)
                  _buildSuperAdminStatsGrid(
                    isRtl: isRtl,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 26),

                  // 12 System Modules Grid
                  _buildSuperAdminModulesGrid(
                    isRtl: isRtl,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 26),

                  // Recent Activities Stream
                  _buildRecentActivities(
                    isRtl: isRtl,
                    isDark: isDark,
                    isWide: isWide,
                  ),
                  const SizedBox(height: 24),

                  // Super Admin Quick Creation Actions
                  _buildSuperAdminQuickActions(
                    isRtl: isRtl,
                    isDark: isDark,
                    isWide: isWide,
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. WELCOME HEADER
  // ===========================================================================
  Widget _buildWelcomeHeader({
    required String displayName,
    required String userRoleLabel,
    required bool isStoreManager,
    required bool isRtl,
    required bool isDark,
    required bool isWide,
  }) {
    final subtitle = isStoreManager
        ? (isRtl
            ? 'إدارة كتالوج متجرك، والمنشورات الأسبوعية، وعروض الخصم، وفروع المتجر، والحملات الترويجية.'
            : 'Manage your store catalog, published weekly flyers, discount deals, branch locations, and customer promotions.')
        : (isRtl
            ? 'لوحة التحكم ومركز الإدارة الشاملة للكتالوجات، والشركاء التجاريين، والعروض، وعمليات النظام.'
            : 'Control panel and quick management center for catalogs, retail partners, promotions, and system operations.');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 28 : 18,
        vertical: isWide ? 22 : 18,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? 'مرحباً، $displayName' : 'Welcome, $displayName',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                _buildRoleBadge(
                  label: userRoleLabel,
                  isStoreManager: isStoreManager,
                  isDark: isDark,
                ),
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
                    _buildRoleBadge(
                      label: userRoleLabel,
                      isStoreManager: isStoreManager,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRoleBadge({
    required String label,
    required bool isStoreManager,
    required bool isDark,
  }) {
    final color = isStoreManager ? const Color(0xFF2563EB) : const Color(0xFF16A34A);
    final icon = isStoreManager ? Icons.storefront_rounded : Icons.verified_user_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. STORE MANAGER: HERO CARD
  // ===========================================================================
  Widget _buildStoreHeroCard({
    required Store store,
    required bool isRtl,
    required bool isDark,
    required bool isWide,
  }) {
    final storeName = isRtl ? store.nameAr : store.nameEn;
    final cityName = isRtl ? (store.cityNameAr ?? store.city?.nameAr ?? '') : (store.cityNameEn ?? store.city?.nameEn ?? '');
    final categoryName = isRtl ? (store.categoryNameAr ?? store.category?.nameAr ?? '') : (store.categoryNameEn ?? store.category?.nameEn ?? '');
    final isVerified = store.isVerified == 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF1E293B) : Colors.white,
            (isDark ? const Color(0xFF065F46) : const Color(0xFFECFDF5)).withValues(alpha: 0.25),
          ],
        ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Logo Box
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppNetworkImage(
                imageUrl: store.logoUrl,
                fit: BoxFit.contain,
                defaultFallbackIcon: Icons.store_rounded,
                fallbackIconSize: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title, Verified Badge & Public Link
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      storeName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              isRtl ? 'متجر معتمد' : 'Verified Store',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Public Storefront Link Button
                    InkWell(
                      onTap: () => context.push('/stores/${store.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isRtl ? 'صفحة المتجر' : 'Public Page',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Meta Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (cityName.isNotEmpty)
                      _buildMetaChip(
                        icon: Icons.place_rounded,
                        label: cityName,
                        isDark: isDark,
                      ),
                    if (categoryName.isNotEmpty)
                      _buildMetaChip(
                        icon: Icons.category_rounded,
                        label: categoryName,
                        isDark: isDark,
                      ),
                    if (store.crNumber != null && store.crNumber!.isNotEmpty)
                      _buildMetaChip(
                        icon: Icons.badge_rounded,
                        label: 'CR: ${store.crNumber}',
                        isDark: isDark,
                      ),
                    if (store.vatNumber != null && store.vatNumber!.isNotEmpty)
                      _buildMetaChip(
                        icon: Icons.receipt_long_rounded,
                        label: 'VAT: ${store.vatNumber}',
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. STORE MANAGER: LIVE METRICS STRIP (5 pills)
  // ===========================================================================
  Widget _buildStoreStatsStrip({
    required bool isRtl,
    required bool isDark,
  }) {
    final pills = [
      _StatPillData(
        number: _storeOffersCount,
        labelEn: 'Active Deals',
        labelAr: 'العروض النشطة',
        icon: Icons.local_offer_rounded,
        color: const Color(0xFF2563EB),
      ),
      _StatPillData(
        number: _storeFlyersCount,
        labelEn: 'Published Flyers',
        labelAr: 'المنشورات',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFD97706),
      ),
      _StatPillData(
        number: _storeBranchesCount,
        labelEn: 'Branches',
        labelAr: 'الفروع',
        icon: Icons.store_rounded,
        color: const Color(0xFF16A34A),
      ),
      _StatPillData(
        number: _storeFollowersCount,
        labelEn: 'Followers',
        labelAr: 'المتابعون',
        icon: Icons.people_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _StatPillData(
        number: _storeCouponsCount,
        labelEn: 'Active Coupons',
        labelAr: 'الكوبونات',
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFFEA580C),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width >= 1000 ? 5 : (width >= 600 ? 3 : 2);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: pills.map((p) {
            final itemWidth = (width - (count - 1) * 12) / count;
            return SizedBox(
              width: itemWidth > 0 ? itemWidth : width,
              child: _buildStoreStatPill(
                data: p,
                isRtl: isRtl,
                isDark: isDark,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStoreStatPill({
    required _StatPillData data,
    required bool isRtl,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${data.number}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isRtl ? data.labelAr : data.labelEn,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. STORE MANAGER: MODULES GRID (5 modules)
  // ===========================================================================
  Widget _buildStoreModulesGrid({
    required int? storeId,
    required bool isRtl,
    required bool isDark,
  }) {
    final branchRoute = storeId != null ? '/admin/stores/$storeId/branches' : '/admin/stores';

    final storeModules = [
      _ModuleCardData(
        route: branchRoute,
        icon: Icons.store_rounded,
        titleEn: 'My Store Branches',
        titleAr: 'فروع المتجر',
        descEn: 'Manage physical branch locations, coordinates, cities, and opening hours.',
        descAr: 'إدارة مواقع الفروع الفعلية، الإحداثيات، المدن، وأوقات العمل.',
        color: const Color(0xFF16A34A),
        bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFDCFCE7),
      ),
      _ModuleCardData(
        route: '/admin/offers',
        icon: Icons.local_offer_rounded,
        titleEn: 'My Offers & Discounts',
        titleAr: 'عروض وتخفيضات المتجر',
        descEn: 'Publish discounts, flash deals, featured promotions, and special pricing.',
        descAr: 'نشر الخصومات، صفقات الفلاش، العروض الترويجية والأسعار الخاصة.',
        color: const Color(0xFF2563EB),
        bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFDBEAFE),
      ),
      _ModuleCardData(
        route: '/admin/flyers',
        icon: Icons.menu_book_rounded,
        titleEn: 'My Weekly Flyers & Brochures',
        titleAr: 'مجلات وكتالوجات المتجر',
        descEn: 'Upload and organize promotional flyer catalog pages, covers, and validity.',
        descAr: 'رفع وتنظيم صفحات كتالوجات العروض الترويجية، الأغلفة، والصلاحية.',
        color: const Color(0xFFD97706),
        bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
      ),
      _ModuleCardData(
        route: '/admin/products',
        icon: Icons.shopping_bag_rounded,
        titleEn: 'Product Items & Catalog',
        titleAr: 'كتالوج المنتجات',
        descEn: 'Browse official products, SKU codes, and specifications to link with offers.',
        descAr: 'استعراض المنتجات المعتمدة، أكواد SKU، والمواصفات لربطها بالعروض.',
        color: const Color(0xFF0D9488),
        bgColor: isDark ? const Color(0xFF042F2E).withValues(alpha: 0.35) : const Color(0xFFCCFBF1),
      ),
      _ModuleCardData(
        route: '/admin/coupons',
        icon: Icons.confirmation_number_rounded,
        titleEn: 'My Promo Coupons',
        titleAr: 'كوبونات الخصم',
        descEn: 'Create discount coupon codes, usage limits, and promotional vouchers.',
        descAr: 'إنشاء قسائم وأكواد الخصم، وتحديد فترات الصلاحية وحدود الاستخدام.',
        color: const Color(0xFFEA580C),
        bgColor: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFEDD5),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRtl ? 'أدوات إدارة المتجر' : 'Store Management Tools',
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
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int crossAxisCount = width >= 1100
                ? 3
                : (width >= 680 ? 2 : 1);
            final double childAspectRatio = width >= 1100
                ? 2.1
                : (width >= 680 ? 2.1 : 3.0);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: storeModules.length,
              itemBuilder: (context, index) {
                final m = storeModules[index];
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
    );
  }

  // ===========================================================================
  // 5. STORE MANAGER: QUICK ACTIONS
  // ===========================================================================
  Widget _buildStoreQuickActions({
    required int? storeId,
    required bool isRtl,
    required bool isDark,
    required bool isWide,
  }) {
    final branchRoute = storeId != null ? '/admin/stores/$storeId/branches' : '/admin/stores';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 26 : 18,
        vertical: isWide ? 22 : 18,
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
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Color(0xFFEAB308), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl ? 'إجراءات المتجر السريعة' : 'Store Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionBtn(
                context: context,
                route: '/admin/offers',
                icon: Icons.add_circle_rounded,
                label: isRtl ? 'إضافة عرض جديد' : 'Add New Offer',
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.12),
                borderColor: const Color(0xFF2563EB).withValues(alpha: 0.25),
              ),
              _buildQuickActionBtn(
                context: context,
                route: '/admin/flyers',
                icon: Icons.upload_file_rounded,
                label: isRtl ? 'رفع منشور جديد' : 'Upload New Flyer',
                color: const Color(0xFFB45309),
                bgColor: const Color(0xFFEAB308).withValues(alpha: isDark ? 0.2 : 0.15),
                borderColor: const Color(0xFFEAB308).withValues(alpha: 0.3),
              ),
              _buildQuickActionBtn(
                context: context,
                route: branchRoute,
                icon: Icons.add_location_alt_rounded,
                label: isRtl ? 'إدارة الفروع' : 'Manage Branches',
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFF16A34A).withValues(alpha: isDark ? 0.2 : 0.12),
                borderColor: const Color(0xFF16A34A).withValues(alpha: 0.25),
              ),
              _buildQuickActionBtn(
                context: context,
                route: '/admin/coupons',
                icon: Icons.confirmation_number_rounded,
                label: isRtl ? 'إنشاء كوبون' : 'Create Coupon',
                color: const Color(0xFFC2410C),
                bgColor: const Color(0xFFF97316).withValues(alpha: isDark ? 0.2 : 0.12),
                borderColor: const Color(0xFFF97316).withValues(alpha: 0.25),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. SUPER ADMIN: STATS GRID (5 stat cards)
  // ===========================================================================
  Widget _buildSuperAdminStatsGrid({
    required bool isRtl,
    required bool isDark,
  }) {
    final stats = [
      _PlatformStatData(
        route: '/admin/stores',
        icon: Icons.store_rounded,
        number: _totalStoresCount,
        labelEn: 'Partner Stores',
        labelAr: 'المتاجر الشريكة',
        color: const Color(0xFF16A34A),
      ),
      _PlatformStatData(
        route: '/admin/offers',
        icon: Icons.local_offer_rounded,
        number: _totalOffersCount,
        labelEn: 'Active Offers',
        labelAr: 'العروض والتخفيضات',
        color: const Color(0xFF2563EB),
      ),
      _PlatformStatData(
        route: '/admin/flyers',
        icon: Icons.menu_book_rounded,
        number: _totalFlyersCount,
        labelEn: 'Weekly Flyers',
        labelAr: 'المجلات والمنشورات',
        color: const Color(0xFFD97706),
      ),
      _PlatformStatData(
        route: '/admin/partner-requests',
        icon: Icons.handshake_rounded,
        number: _pendingPartnerRequestsCount,
        labelEn: 'Pending Applications',
        labelAr: 'طلبات الانضمام المعلقة',
        color: const Color(0xFFB45309),
      ),
      _PlatformStatData(
        route: '/admin/coupons',
        icon: Icons.confirmation_number_rounded,
        number: _totalCouponsCount,
        labelEn: 'Promo Coupons',
        labelAr: 'كوبونات الخصم',
        color: const Color(0xFFEA580C),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width >= 1100 ? 5 : (width >= 700 ? 3 : (width >= 450 ? 2 : 1));

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: stats.map((s) {
            final itemWidth = (width - (count - 1) * 14) / count;
            return SizedBox(
              width: itemWidth > 0 ? itemWidth : width,
              child: _buildPlatformStatCard(
                data: s,
                isRtl: isRtl,
                isDark: isDark,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlatformStatCard({
    required _PlatformStatData data,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${data.number}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRtl ? data.labelAr : data.labelEn,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. SUPER ADMIN: 12 SYSTEM MODULES GRID
  // ===========================================================================
  Widget _buildSuperAdminModulesGrid({
    required bool isRtl,
    required bool isDark,
  }) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  // ===========================================================================
  // 8. SUPER ADMIN: RECENT ACTIVITIES STREAM
  // ===========================================================================
  Widget _buildRecentActivities({
    required bool isRtl,
    required bool isDark,
    required bool isWide,
  }) {
    final auditState = ref.watch(auditLogRepositoryProvider);
    final hasActivities = auditState.recentActivities.isNotEmpty;
    final hasLogs = auditState.logs.isNotEmpty;

    if (!hasActivities && !hasLogs && !auditState.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 26 : 18,
        vertical: isWide ? 22 : 18,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? 'سجل النشاطات الحديثة' : 'Recent Audit Activities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isRtl ? 'آخر العمليات والتغييرات المنفذة على المنصة' : 'Latest administrative changes and operations',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/admin/audit-logs'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRtl ? 'عرض الكل' : 'View All',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isRtl ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (auditState.isLoading && !hasActivities && !hasLogs)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (hasActivities)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: auditState.recentActivities.length > 5 ? 5 : auditState.recentActivities.length,
              separatorBuilder: (_, __) => Divider(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                height: 20,
              ),
              itemBuilder: (context, index) {
                final item = auditState.recentActivities[index];
                return _buildRecentActivityRow(item, isRtl, isDark);
              },
            )
          else if (hasLogs)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: auditState.logs.length > 5 ? 5 : auditState.logs.length,
              separatorBuilder: (_, __) => Divider(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                height: 20,
              ),
              itemBuilder: (context, index) {
                final log = auditState.logs[index];
                return _buildAuditLogRow(log, isRtl, isDark);
              },
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  isRtl ? 'لا توجد نشاطات مسجلة حالياً' : 'No recent activities recorded yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityRow(RecentActivity item, bool isRtl, bool isDark) {
    final act = (item.action ?? '').toUpperCase();
    final Color badgeColor;
    final IconData badgeIcon;

    if (act == 'CREATE') {
      badgeColor = const Color(0xFF10B981);
      badgeIcon = Icons.add_circle_outline_rounded;
    } else if (act == 'UPDATE') {
      badgeColor = const Color(0xFF3B82F6);
      badgeIcon = Icons.edit_note_rounded;
    } else if (act == 'DELETE') {
      badgeColor = const Color(0xFFEF4444);
      badgeIcon = Icons.delete_outline_rounded;
    } else if (act == 'APPROVE') {
      badgeColor = const Color(0xFF0D9488);
      badgeIcon = Icons.check_circle_outline_rounded;
    } else if (act == 'REJECT') {
      badgeColor = const Color(0xFFF59E0B);
      badgeIcon = Icons.highlight_off_rounded;
    } else {
      badgeColor = const Color(0xFF6366F1);
      badgeIcon = Icons.bolt_rounded;
    }

    String formattedDate = '';
    if (item.timestamp != null) {
      try {
        final parsed = DateTime.parse(item.timestamp!);
        formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
      } catch (_) {
        formattedDate = item.timestamp!;
      }
    }

    return InkWell(
      onTap: () => context.go('/admin/audit-logs'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(badgeIcon, size: 20, color: badgeColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.action ?? 'ACTIVITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (item.entityType != null && item.entityType!.isNotEmpty) ...[
                        Text(
                          item.entityType!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description ?? item.message ?? item.title ?? '${item.action ?? "Activity"} on ${item.entityType ?? "item"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.performedBy != null && item.performedBy!.isNotEmpty) ...[
                        Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.performedBy!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (formattedDate.isNotEmpty) ...[
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogRow(AuditLog item, bool isRtl, bool isDark) {
    final act = item.action.toUpperCase();
    final Color badgeColor;
    final IconData badgeIcon;

    if (act == 'CREATE') {
      badgeColor = const Color(0xFF10B981);
      badgeIcon = Icons.add_circle_outline_rounded;
    } else if (act == 'UPDATE') {
      badgeColor = const Color(0xFF3B82F6);
      badgeIcon = Icons.edit_note_rounded;
    } else if (act == 'DELETE') {
      badgeColor = const Color(0xFFEF4444);
      badgeIcon = Icons.delete_outline_rounded;
    } else if (act == 'APPROVE') {
      badgeColor = const Color(0xFF0D9488);
      badgeIcon = Icons.check_circle_outline_rounded;
    } else if (act == 'REJECT') {
      badgeColor = const Color(0xFFF59E0B);
      badgeIcon = Icons.highlight_off_rounded;
    } else {
      badgeColor = const Color(0xFF6366F1);
      badgeIcon = Icons.bolt_rounded;
    }

    String formattedDate = '';
    if (item.createdAt.isNotEmpty) {
      try {
        final parsed = DateTime.parse(item.createdAt);
        formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
      } catch (_) {
        formattedDate = item.createdAt;
      }
    }

    final userLabel = item.performedBy != null
        ? '${item.performedBy!.fullName} (${item.performedBy!.role})'
        : (item.performedById != null ? 'User #${item.performedById}' : 'System');

    return InkWell(
      onTap: () => context.go('/admin/audit-logs'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(badgeIcon, size: 20, color: badgeColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.action,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.entityType}${item.entityId != null ? ' #${item.entityId}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.action} performed on ${item.entityType}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        userLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 9. SUPER ADMIN: QUICK ACTIONS
  // ===========================================================================
  Widget _buildSuperAdminQuickActions({
    required bool isRtl,
    required bool isDark,
    required bool isWide,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 26 : 18,
        vertical: isWide ? 22 : 18,
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
              // Partner Requests (.btn-partner)
              _buildQuickActionBtn(
                context: context,
                route: '/admin/partner-requests',
                icon: Icons.handshake_rounded,
                label: isRtl ? 'طلبات الشراكة' : 'Partner Requests',
                color: const Color(0xFFB45309),
                bgColor: const Color(0xFFB45309).withValues(alpha: isDark ? 0.2 : 0.12),
                borderColor: const Color(0xFFB45309).withValues(alpha: 0.25),
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
    );
  }

  // ===========================================================================
  // COMMON HELPER WIDGETS
  // ===========================================================================
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
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: data.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 24),
                ),
                const SizedBox(width: 14),
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
                          fontSize: 14.5,
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
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
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

class _StatPillData {
  final int number;
  final String labelEn;
  final String labelAr;
  final IconData icon;
  final Color color;

  const _StatPillData({
    required this.number,
    required this.labelEn,
    required this.labelAr,
    required this.icon,
    required this.color,
  });
}

class _PlatformStatData {
  final String route;
  final IconData icon;
  final int number;
  final String labelEn;
  final String labelAr;
  final Color color;

  const _PlatformStatData({
    required this.route,
    required this.icon,
    required this.number,
    required this.labelEn,
    required this.labelAr,
    required this.color,
  });
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
