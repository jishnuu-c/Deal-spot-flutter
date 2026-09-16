import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/models.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/partner_request_repository.dart';
import '../../../../core/services/notification_repository.dart';
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
    AdminMenuItem(route: '/admin', labelEn: 'Dashboard', labelAr: 'الرئيسية', icon: Icons.dashboard_rounded),
    AdminMenuItem(route: '/admin/partner-requests', labelEn: 'Partner Requests', labelAr: 'طلبات الشراكة', icon: Icons.handshake_rounded),
    AdminMenuItem(route: '/admin/cities', labelEn: 'Cities', labelAr: 'المدن', icon: Icons.place_rounded),
    AdminMenuItem(route: '/admin/categories', labelEn: 'Categories', labelAr: 'الأقسام', icon: Icons.category_rounded),
    AdminMenuItem(route: '/admin/brands', labelEn: 'Brands', labelAr: 'الماركات', icon: Icons.loyalty_rounded),
    AdminMenuItem(route: '/admin/stores', labelEn: 'Stores', labelAr: 'المتاجر', icon: Icons.store_rounded),
    AdminMenuItem(route: '/admin/products', labelEn: 'Products', labelAr: 'المنتجات', icon: Icons.shopping_bag_rounded),
    AdminMenuItem(route: '/admin/offers', labelEn: 'Offers', labelAr: 'العروض', icon: Icons.local_offer_rounded),
    AdminMenuItem(route: '/admin/flyers', labelEn: 'Flyers', labelAr: 'المنشورات', icon: Icons.menu_book_rounded),
    AdminMenuItem(route: '/admin/coupons', labelEn: 'Coupons', labelAr: 'الكوبونات', icon: Icons.confirmation_number_rounded),
    AdminMenuItem(route: '/admin/users', labelEn: 'Staff & Admins', labelAr: 'المشرفين', icon: Icons.people_rounded),
    AdminMenuItem(route: '/admin/notifications', labelEn: 'Notifications', labelAr: 'الإشعارات', icon: Icons.notifications_rounded),
    AdminMenuItem(route: '/admin/audit-logs', labelEn: 'Audit Logs', labelAr: 'سجل العمليات', icon: Icons.history_edu_rounded),
  ];

  String _getPageTitle(bool isRtl) {
    return isRtl ? 'لوحة الإدارة' : 'Dashboard Control';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String location = '/admin';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {}
    final authState = ref.watch(authProvider);
    final adminUser = authState.currentAdmin;
    final role = (adminUser?.role ?? 'SUPER_ADMIN').toUpperCase();
    final storeId = adminUser?.storeId;

    final List<AdminMenuItem> menuItems = authState.isStoreManager
        ? [
            const AdminMenuItem(route: '/admin', labelEn: 'Store Dashboard', labelAr: 'لوحة المتجر', icon: Icons.dashboard_rounded),
            AdminMenuItem(
              route: storeId != null ? '/admin/stores/$storeId/branches' : '/admin/stores',
              labelEn: 'My Branches',
              labelAr: 'فروع متجري',
              icon: Icons.store_rounded,
            ),
            const AdminMenuItem(route: '/admin/products', labelEn: 'My Products', labelAr: 'منتجات المتجر', icon: Icons.shopping_bag_rounded),
            const AdminMenuItem(route: '/admin/offers', labelEn: 'My Offers & Deals', labelAr: 'عروض متجري', icon: Icons.local_offer_rounded),
            const AdminMenuItem(route: '/admin/flyers', labelEn: 'My Flyers', labelAr: 'منشورات متجري', icon: Icons.menu_book_rounded),
            const AdminMenuItem(route: '/admin/coupons', labelEn: 'My Coupons', labelAr: 'كوبونات الخصم', icon: Icons.confirmation_number_rounded),
          ]
        : _allMenuItems;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 992;
    final pageTitle = _getPageTitle(isRtl);

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
                  // Fixed Desktop Sidebar (260px wide, matching Angular)
                  SizedBox(
                    width: 260,
                    child: sidebarWidget,
                  ),
                  // Main Content Viewport on Desktop
                  Expanded(
                    child: Column(
                      children: [
                        _AdminTopBar(
                          pageTitle: pageTitle,
                          adminUser: adminUser,
                          isRtl: isRtl,
                          isDark: isDark,
                          isDesktop: true,
                          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
                    _AdminTopBar(
                      pageTitle: pageTitle,
                      adminUser: adminUser,
                      isRtl: isRtl,
                      isDark: isDark,
                      isDesktop: false,
                      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
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
          // Sidebar Header (.sidebar-header)
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
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
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
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),

          // Navigation Links List (.sidebar-nav)
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
                            if (!isDesktop && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
                              _scaffoldKey.currentState?.closeDrawer();
                            }
                            if (location != route) {
                              context.go(route);
                            }
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

          // Sidebar Footer: "View Website" link (.sidebar-footer)
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
                hoverColor: const Color(0xFF334155),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility_rounded, color: Color(0xFF16A34A), size: 18),
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

/// Admin TopBar Component - Pixel-perfect match for Angular admin-topbar
class _AdminTopBar extends ConsumerStatefulWidget {
  final String pageTitle;
  final dynamic adminUser;
  final bool isRtl;
  final bool isDark;
  final bool isDesktop;
  final VoidCallback onMenuPressed;

  const _AdminTopBar({
    required this.pageTitle,
    required this.adminUser,
    required this.isRtl,
    required this.isDark,
    required this.isDesktop,
    required this.onMenuPressed,
  });

  @override
  ConsumerState<_AdminTopBar> createState() => _AdminTopBarState();
}

class _AdminTopBarState extends ConsumerState<_AdminTopBar> {
  final LayerLink _notifLayerLink = LayerLink();
  final OverlayPortalController _notifOverlayController = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth <= 576;
    final topbarHeight = widget.isDesktop ? 70.0 : (isSmallPhone ? 58.0 : 64.0);
    final horizontalPadding = widget.isDesktop ? 28.0 : (isSmallPhone ? 12.0 : 16.0);
    final role = (widget.adminUser?.role ?? 'SUPER_ADMIN').toString().toUpperCase();

    return Container(
      height: topbarHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left Area: Hamburger (Mobile) + Admin Page Title ──
          Expanded(
            child: Row(
              children: [
                if (!widget.isDesktop) ...[
                  // .btn-hamburger
                  Container(
                    width: isSmallPhone ? 36 : 40,
                    height: isSmallPhone ? 36 : 40,
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.menu_rounded, size: 22),
                      color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                      tooltip: widget.isRtl ? 'القائمة الرئيسية' : 'Toggle Navigation Menu',
                      onPressed: widget.onMenuPressed,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // .admin-page-title
                Flexible(
                  child: Text(
                    widget.pageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.isDesktop ? 18 : (isSmallPhone ? 14 : 16),
                      fontWeight: FontWeight.w800,
                      color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Right Area: Notifications, Lang Toggle, User Info, Logout ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Notification Bell Popover Trigger (.notif-dropdown-wrapper)
              _buildNotificationBell(isSmallPhone),
              SizedBox(width: isSmallPhone ? 8 : 12),

              // 2. Language Switcher (.lang-toggle)
              _buildLanguageToggle(isSmallPhone),
              SizedBox(width: isSmallPhone ? 8 : 14),

              // 3. Admin User Profile (.admin-user-profile)
              _buildAdminUserProfile(role, isSmallPhone),
              SizedBox(width: isSmallPhone ? 8 : 12),

              // 4. Logout Button (.btn-logout)
              _buildLogoutButton(isSmallPhone),
            ],
          ),
        ],
      ),
    );
  }

  // 1. Notification Bell with Dropdown Popover (.notif-dropdown-wrapper)
  Widget _buildNotificationBell(bool isSmallPhone) {
    final notifState = ref.watch(notificationRepositoryProvider);
    final unreadCount = notifState.unreadCount;
    final btnSize = isSmallPhone ? 36.0 : 40.0;

    return CompositedTransformTarget(
      link: _notifLayerLink,
      child: OverlayPortal(
        controller: _notifOverlayController,
        overlayChildBuilder: (context) {
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final isSmallPhoneLocal = screenWidth <= 576;
          final isMobile = screenWidth < 768 || !widget.isDesktop;
          final topbarH = widget.isDesktop ? 70.0 : (isSmallPhoneLocal ? 58.0 : 64.0);

          return Stack(
            children: [
              // Backdrop click-to-close overlay (.notif-menu-backdrop)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _notifOverlayController.hide(),
                  child: const SizedBox.expand(),
                ),
              ),
              // Floating Notification Popover Dropdown (.notif-dropdown-popover)
              if (isMobile)
                Positioned(
                  top: mediaQuery.padding.top + topbarH + 6,
                  left: 10,
                  right: 10,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buildNotificationDropdown(notifState, isMobile: true),
                    ),
                  ),
                )
              else
                CompositedTransformFollower(
                  link: _notifLayerLink,
                  showWhenUnlinked: false,
                  targetAnchor: widget.isRtl ? Alignment.bottomLeft : Alignment.bottomRight,
                  followerAnchor: widget.isRtl ? Alignment.topLeft : Alignment.topRight,
                  offset: const Offset(0, 10),
                  child: _buildNotificationDropdown(notifState, isMobile: false),
                ),
            ],
          );
        },
        child: Container(
          width: btnSize,
          height: btnSize,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    size: isSmallPhone ? 19 : 21,
                    color: widget.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                  tooltip: widget.isRtl ? 'الإشعارات' : 'Notifications',
                  onPressed: () => _notifOverlayController.toggle(),
                ),
              ),
              // .notif-badge-pill
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: widget.isRtl ? null : -4,
                  left: widget.isRtl ? -4 : null,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Notification Dropdown Popover Card (.notif-dropdown-popover)
  Widget _buildNotificationDropdown(NotificationState notifState, {bool isMobile = false}) {
    final recent = notifState.notifications.take(5).toList();
    final unreadCount = notifState.unreadCount;

    return Directionality(
      textDirection: widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: isMobile ? double.infinity : 360,
          constraints: const BoxConstraints(
            maxHeight: 480,
          ),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.45 : 0.15),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header (.notif-popover-header) ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.isRtl ? 'الإشعارات' : 'Notifications',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                '$unreadCount ${widget.isRtl ? 'جديد' : 'New'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ref.read(notificationRepositoryProvider.notifier).markAllAsRead();
                        },
                        child: Text(
                          widget.isRtl ? 'تعليم الكل كمقروء' : 'Mark all as read',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Body (.notif-popover-body) ──
              Flexible(
                child: recent.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 36,
                              color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isRtl ? 'لا توجد إشعارات حالياً' : 'No notifications yet',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: recent.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final item = recent[index];
                          final isUnread = item.isRead == 0;
                          final title = widget.isRtl
                              ? (item.titleAr.isNotEmpty ? item.titleAr : item.titleEn)
                              : item.titleEn;
                          final body = widget.isRtl
                              ? (item.bodyAr ?? item.bodyEn ?? '')
                              : (item.bodyEn ?? item.bodyAr ?? '');

                          return InkWell(
                            onTap: () {
                              if (isUnread) {
                                ref.read(notificationRepositoryProvider.notifier).markAsRead(item.id);
                              }
                              _notifOverlayController.hide();
                              if (item.deepLink != null && item.deepLink!.isNotEmpty) {
                                context.go(item.deepLink!);
                              }
                            },
                            child: Container(
                              color: isUnread
                                  ? const Color(0xFF16A34A).withValues(alpha: widget.isDark ? 0.08 : 0.04)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Channel Icon Box (.item-icon-box)
                                  _buildChannelIconBox(item.channel),
                                  const SizedBox(width: 10),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            if (isUnread)
                                              Container(
                                                width: 6,
                                                height: 6,
                                                margin: const EdgeInsets.only(left: 6),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF16A34A),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (body.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 3),
                                        Text(
                                          _formatNotificationTime(item.sentAt),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // ── Footer (.notif-popover-footer) ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  border: Border(
                    top: BorderSide(
                      color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    _notifOverlayController.hide();
                    context.go('/admin/notifications');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.isRtl ? 'عرض كافة الإشعارات والبث' : 'View All Notifications & Broadcast',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        widget.isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                        size: 14,
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Channel Icon Box (SMS: purple, EMAIL: blue, PUSH: red)
  Widget _buildChannelIconBox(String channel) {
    Color bg;
    Color iconColor;
    IconData icon;

    switch (channel.toUpperCase()) {
      case 'SMS':
        bg = const Color(0xFFFAF5FF);
        iconColor = const Color(0xFF7E22CE);
        icon = Icons.sms_rounded;
        break;
      case 'EMAIL':
        bg = const Color(0xFFEFF6FF);
        iconColor = const Color(0xFF2563EB);
        icon = Icons.mail_rounded;
        break;
      default:
        bg = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFDC2626);
        icon = Icons.campaign_rounded;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }

  String _formatNotificationTime(String sentAt) {
    try {
      final dt = DateTime.parse(sentAt);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return sentAt;
    }
  }

  // 2. Language Switcher (.lang-toggle)
  Widget _buildLanguageToggle(bool isSmallPhone) {
    final btnSize = isSmallPhone ? 36.0 : 40.0;
    return Container(
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => ref.read(translationProvider.notifier).toggleLanguage(),
          hoverColor: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          child: Center(
            child: Text(
              widget.isRtl ? 'EN' : 'AR',
              style: TextStyle(
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Admin User Profile (.admin-user-profile)
  Widget _buildAdminUserProfile(String role, bool isSmallPhone) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showUserInfo = screenWidth > 576;
    final fullName = widget.adminUser?.fullName ?? (widget.isRtl ? 'المشرف' : 'Administrator');
    final formattedRole = role == 'STORE_MANAGER'
        ? (widget.isRtl ? 'مدير المتجر' : 'Store Manager')
        : (role == 'SUPER_ADMIN'
            ? (widget.isRtl ? 'المدير العام' : 'Super Administrator')
            : (widget.adminUser?.role ?? 'SUPER_ADMIN'));

    return Container(
      padding: EdgeInsets.only(
        left: widget.isRtl ? 0 : (isSmallPhone ? 8 : 14),
        right: widget.isRtl ? (isSmallPhone ? 8 : 14) : 0,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: widget.isRtl
              ? BorderSide.none
              : BorderSide(
                  color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
          right: widget.isRtl
              ? BorderSide(
                  color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // .admin-user-avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF16A34A), size: 20),
          ),
          if (showUserInfo) ...[
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                Text(
                  formattedRole,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 4. Logout Button (.btn-logout)
  Widget _buildLogoutButton(bool isSmallPhone) {
    final btnSize = isSmallPhone ? 36.0 : 40.0;
    return Container(
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ref.read(authProvider.notifier).logout();
            context.go('/login?admin=true');
          },
          hoverColor: const Color(0xFFDC2626).withValues(alpha: 0.12),
          child: Center(
            child: Icon(
              Icons.logout_rounded,
              size: isSmallPhone ? 19 : 20,
              color: const Color(0xFFDC2626),
            ),
          ),
        ),
      ),
    );
  }
}
