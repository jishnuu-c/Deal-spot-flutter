import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/models.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/partner_request_repository.dart';
import '../../../../core/utils/translation_service.dart';

class AdminMenuItem {
  final String route;
  final String labelEn;
  final String labelAr;
  final IconData icon;

  const AdminMenuItem({
    required this.route,
    required this.labelEn,
    required this.labelAr,
    required this.icon,
  });
}

class AdminLayout extends ConsumerStatefulWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Menu items matching Angular AdminLayoutComponent
  static const List<AdminMenuItem> _allMenuItems = [
    AdminMenuItem(route: '/admin', labelEn: 'Dashboard', labelAr: 'الرئيسية', icon: Icons.dashboard_outlined),
    AdminMenuItem(route: '/admin/partner-requests', labelEn: 'Partner Requests', labelAr: 'طلبات الشراكة', icon: Icons.handshake_outlined),
    AdminMenuItem(route: '/admin/cities', labelEn: 'Cities', labelAr: 'المدن', icon: Icons.location_city_outlined),
    AdminMenuItem(route: '/admin/categories', labelEn: 'Categories', labelAr: 'الأقسام', icon: Icons.category_outlined),
    AdminMenuItem(route: '/admin/brands', labelEn: 'Brands', labelAr: 'الماركات', icon: Icons.loyalty_outlined),
    AdminMenuItem(route: '/admin/stores', labelEn: 'Stores', labelAr: 'المتاجر', icon: Icons.storefront_outlined),
    AdminMenuItem(route: '/admin/products', labelEn: 'Products', labelAr: 'المنتجات', icon: Icons.inventory_2_outlined),
    AdminMenuItem(route: '/admin/offers', labelEn: 'Offers', labelAr: 'العروض', icon: Icons.local_offer_outlined),
    AdminMenuItem(route: '/admin/flyers', labelEn: 'Flyers', labelAr: 'المنشورات', icon: Icons.menu_book_outlined),
    AdminMenuItem(route: '/admin/coupons', labelEn: 'Coupons', labelAr: 'الكوبونات', icon: Icons.confirmation_number_outlined),
    AdminMenuItem(route: '/admin/users', labelEn: 'Staff & Admins', labelAr: 'المشرفين', icon: Icons.people_outline),
    AdminMenuItem(route: '/admin/notifications', labelEn: 'Notifications', labelAr: 'الإشعارات', icon: Icons.notifications_outlined),
    AdminMenuItem(route: '/admin/audit-logs', labelEn: 'Audit Logs', labelAr: 'سجل العمليات', icon: Icons.history_edu_outlined),
  ];

  static const List<AdminMenuItem> _storeManagerMenuItems = [
    AdminMenuItem(route: '/admin', labelEn: 'Store Dashboard', labelAr: 'لوحة المتجر', icon: Icons.dashboard_outlined),
    AdminMenuItem(route: '/admin/stores', labelEn: 'My Branches', labelAr: 'فروع متجري', icon: Icons.storefront_outlined),
    AdminMenuItem(route: '/admin/products', labelEn: 'My Products', labelAr: 'منتجات المتجر', icon: Icons.inventory_2_outlined),
    AdminMenuItem(route: '/admin/offers', labelEn: 'My Offers & Deals', labelAr: 'عروض متجري', icon: Icons.local_offer_outlined),
    AdminMenuItem(route: '/admin/flyers', labelEn: 'My Flyers', labelAr: 'منشورات متجري', icon: Icons.menu_book_outlined),
    AdminMenuItem(route: '/admin/coupons', labelEn: 'My Coupons', labelAr: 'كوبونات الخصم', icon: Icons.confirmation_number_outlined),
  ];

  String _getPageTitle(String location, bool isRtl) {
    if (location == '/admin') return isRtl ? 'لوحة الإدارة' : 'Dashboard Control';
    if (location.startsWith('/admin/partner-requests')) return isRtl ? 'طلبات الشراكة' : 'Partner Requests';
    if (location.startsWith('/admin/cities')) return isRtl ? 'إدارة المدن' : 'Cities Management';
    if (location.startsWith('/admin/categories')) return isRtl ? 'إدارة الأقسام' : 'Categories Management';
    if (location.startsWith('/admin/brands')) return isRtl ? 'إدارة الماركات' : 'Brands Management';
    if (location.startsWith('/admin/stores')) return isRtl ? 'إدارة المتاجر' : 'Stores Management';
    if (location.startsWith('/admin/products')) return isRtl ? 'إدارة المنتجات' : 'Products Management';
    if (location.startsWith('/admin/offers')) return isRtl ? 'إدارة العروض' : 'Offers Management';
    if (location.startsWith('/admin/flyers')) return isRtl ? 'إدارة المنشورات' : 'Flyers Management';
    if (location.startsWith('/admin/coupons')) return isRtl ? 'إدارة الكوبونات' : 'Coupons Management';
    if (location.startsWith('/admin/users')) return isRtl ? 'إدارة المشرفين' : 'Staff & Admins';
    if (location.startsWith('/admin/notifications')) return isRtl ? 'إدارة الإشعارات' : 'Notifications';
    if (location.startsWith('/admin/audit-logs')) return isRtl ? 'سجل العمليات' : 'Audit Logs';
    return isRtl ? 'لوحة التحكم' : 'Control Panel';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(authProvider);
    final adminUser = authState.currentAdmin;
    final role = (adminUser?.role ?? 'SUPER_ADMIN').toUpperCase();
    final menuItems = role == 'STORE_MANAGER' ? _storeManagerMenuItems : _allMenuItems;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 992;
    final pageTitle = _getPageTitle(location, isRtl);

    final sidebarWidget = _buildSidebar(
      context: context,
      menuItems: menuItems,
      location: location,
      isRtl: isRtl,
      isDark: isDark,
      isDesktop: isDesktop,
    );

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        // Drawer is available on mobile/tablet screens
        drawer: isDesktop
            ? null
            : Drawer(
                backgroundColor: const Color(0xFF0F172A),
                child: SafeArea(child: sidebarWidget),
              ),
        body: isDesktop
            ? Row(
                children: [
                  // Fixed Desktop Sidebar (260px wide, exactly like Angular)
                  SizedBox(
                    width: 260,
                    child: sidebarWidget,
                  ),
                  // Main Content Viewport on Desktop
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(
                          context: context,
                          tr: tr,
                          pageTitle: pageTitle,
                          adminUser: adminUser,
                          isRtl: isRtl,
                          isDark: isDark,
                          isDesktop: true,
                        ),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ],
              )
            : SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  children: [
                    // Mobile TopBar with Hamburger Menu
                    _buildTopBar(
                      context: context,
                      tr: tr,
                      pageTitle: pageTitle,
                      adminUser: adminUser,
                      isRtl: isRtl,
                      isDark: isDark,
                      isDesktop: false,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
      ),
    );
  }

  // Top Bar
  Widget _buildTopBar({
    required BuildContext context,
    required AppLocalizations tr,
    required String pageTitle,
    required dynamic adminUser,
    required bool isRtl,
    required bool isDark,
    required bool isDesktop,
  }) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Area: Hamburger (on mobile) + Page Title
          Expanded(
            child: Row(
              children: [
                if (!isDesktop)
                  IconButton(
                    icon: const Icon(Icons.menu, size: 22),
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    tooltip: isRtl ? 'القائمة الرئيسية' : 'Toggle Navigation',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                if (!isDesktop) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    pageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Area: Language toggle, User profile badge, View Site, Logout
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language Switcher (AR / EN)
              OutlinedButton(
                onPressed: () => ref.read(translationProvider.notifier).toggleLanguage(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(36, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
                child: Text(
                  isRtl ? 'EN' : 'AR',
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Admin User Profile Info Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    left: isRtl ? BorderSide.none : BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                    right: isRtl ? BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)) : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.manage_accounts, color: Color(0xFF16A34A), size: 18),
                    ),
                    if (MediaQuery.of(context).size.width >= 600) ...[
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminUser?.fullName ?? (isRtl ? 'المشرف' : 'Administrator'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            adminUser?.role ?? 'SUPER_ADMIN',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Public Site Button (shown on tablet/desktop)
              if (MediaQuery.of(context).size.width >= 460)
                IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 20,
                  ),
                  tooltip: isRtl ? 'عرض الموقع' : 'View Website',
                  onPressed: () => context.go('/'),
                ),

              // Logout Button
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
                tooltip: tr.get('logout'),
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login?admin=true');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sidebar (used for both desktop fixed sidebar and mobile drawer)
  Widget _buildSidebar({
    required BuildContext context,
    required List<AdminMenuItem> menuItems,
    required String location,
    required bool isRtl,
    required bool isDark,
    required bool isDesktop,
  }) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? 'ديل سبوت' : 'DealSpot KSA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        isRtl ? 'لوحة التحكم' : 'Control Panel',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDesktop)
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),

          // Navigation Links List
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final partnerState = ref.watch(partnerRequestRepositoryProvider);
                final pendingPartnerCount = partnerState.requests
                    .where((r) => r.status == PartnerRequestStatus.PENDING)
                    .length;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final route = item.route;
                    final isSelected = route == '/admin'
                        ? location == '/admin'
                        : (location == route || location.startsWith('$route/'));
                    final isPartnerRoute = route == '/admin/partner-requests';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (!isDesktop) {
                              Navigator.of(context).pop();
                            }
                            context.go(route);
                          },
                          hoverColor: const Color(0xFF1E293B),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isRtl ? item.labelAr : item.labelEn,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                                if (isPartnerRoute && pendingPartnerCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      pendingPartnerCount.toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? const Color(0xFF16A34A) : Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Sidebar Footer: "View Website" link
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Material(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (!isDesktop) {
                    Navigator.of(context).pop();
                  }
                  context.go('/');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility_outlined, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isRtl ? 'عرض الموقع' : 'View Website',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
