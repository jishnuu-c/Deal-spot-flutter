import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/notification_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../search/presentation/search_overlay.dart';

class PublicLayout extends ConsumerStatefulWidget {
  final Widget child;

  const PublicLayout({super.key, required this.child});

  @override
  ConsumerState<PublicLayout> createState() => _PublicLayoutState();
}

class _PublicLayoutState extends ConsumerState<PublicLayout> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastBackPressTime;
  final List<String> _historyStack = [];

  void _recordHistory(String location) {
    if (_historyStack.isEmpty || _historyStack.last != location) {
      _historyStack.add(location);
      if (_historyStack.length > 30) {
        _historyStack.removeAt(0);
      }
    }
  }

  void _handleBackPress(BuildContext context, String currentLocation) {
    // 1. If any modal bottom sheet, dialog, or overlay can pop in the Navigator
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    // 2. Remove all trailing entries matching currentLocation
    while (_historyStack.isNotEmpty && _historyStack.last == currentLocation) {
      _historyStack.removeLast();
    }

    // 3. Pop to previous location if present
    if (_historyStack.isNotEmpty) {
      final previousLocation = _historyStack.removeLast();
      context.go(previousLocation);
      return;
    }

    // 4. Hierarchical fallback if history is exhausted
    if (currentLocation != '/') {
      if (currentLocation.startsWith('/offers/')) {
        context.go('/offers');
      } else if (currentLocation.startsWith('/products/')) {
        context.go('/offers');
      } else if (currentLocation.startsWith('/stores/') && currentLocation.contains('/branches')) {
        final parts = currentLocation.split('/');
        final storeId = parts.length > 2 ? parts[2] : '';
        if (storeId.isNotEmpty) {
          context.go('/stores/$storeId');
        } else {
          context.go('/stores');
        }
      } else if (currentLocation.startsWith('/stores/')) {
        context.go('/stores');
      } else if (currentLocation.startsWith('/flyers/')) {
        context.go('/flyers');
      } else if (currentLocation.startsWith('/categories/')) {
        context.go('/offers');
      } else if (currentLocation == '/saved-offers' ||
                 currentLocation == '/followed-stores' ||
                 currentLocation == '/notifications' ||
                 currentLocation == '/partner-with-us') {
        context.go('/profile');
      } else if (currentLocation == '/login' ||
                 currentLocation == '/register' ||
                 currentLocation == '/admin/login') {
        context.go('/');
      } else {
        context.go('/');
      }
      return;
    }

    // 5. User is at Home ('/'): double back to exit cleanly
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      final isAr = ref.read(translationProvider) == AppLanguage.ar;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'اضغط مرة أخرى للخروج من التطبيق' : 'Press back again to exit',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF334155),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/offers')) return 1;
    if (location.startsWith('/stores')) return 2;
    if (location.startsWith('/flyers')) return 3;
    if (location.startsWith('/profile') ||
        location.startsWith('/saved-offers') ||
        location.startsWith('/followed-stores') ||
        location.startsWith('/partner-with-us') ||
        location.startsWith('/login') ||
        location.startsWith('/register') ||
        location.startsWith('/admin/login') ||
        location.startsWith('/notifications')) return 4;
    return 0; // Default Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/offers');
        break;
      case 2:
        context.go('/stores');
        break;
      case 3:
        context.go('/flyers');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  void _openCityModal(BuildContext context, WidgetRef ref) {
    final tr = ref.read(localizationsProvider);
    final isRtl = ref.read(translationProvider) == AppLanguage.ar;
    final cityState = ref.read(cityRepositoryProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sheet Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.place, color: Color(0xFF16A34A), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              tr.get('select_city'),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr.get('select_city_desc'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cities List
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // "All Cities" Option
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cityState.selectedCity == null
                                    ? const Color(0xFF16A34A).withOpacity(0.15)
                                    : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.public,
                                color: cityState.selectedCity == null ? const Color(0xFF16A34A) : Colors.grey,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              isRtl ? 'جميع المدن' : 'All Cities',
                              style: TextStyle(
                                fontWeight: cityState.selectedCity == null ? FontWeight.bold : FontWeight.w500,
                                color: cityState.selectedCity == null ? const Color(0xFF16A34A) : null,
                                fontSize: 14,
                              ),
                            ),
                            trailing: cityState.selectedCity == null
                                ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
                                : null,
                            onTap: () {
                              ref.read(cityRepositoryProvider.notifier).selectCity(null);
                              Navigator.pop(ctx);
                            },
                          ),
                          const Divider(height: 1),

                          // Individual Cities
                          ...cityState.cities.map((city) {
                            final isSelected = city.id == cityState.selectedCity?.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF16A34A).withOpacity(0.15)
                                      : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_city,
                                  color: isSelected ? const Color(0xFF16A34A) : Colors.grey,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                isRtl ? city.nameAr : city.nameEn,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF16A34A) : null,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
                                  : null,
                              onTap: () {
                                ref.read(cityRepositoryProvider.notifier).selectCity(city);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final cityState = ref.watch(cityRepositoryProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int unreadCount = 0;
    if (authState.isLoggedIn && authState.currentUser != null) {
      unreadCount = ref.watch(notificationRepositoryProvider.notifier).getUnreadCount(authState.currentUser!.id);
    }

    final selectedIndex = _calculateSelectedIndex(context);
    final location = GoRouterState.of(context).matchedLocation;
    _recordHistory(location);

    final isDetailRoute = location.contains(RegExp(r'/(offers|stores|flyers|products)/\d+')) ||
        location.startsWith('/categories/') ||
        location.endsWith('/branches') ||
        location.startsWith('/login') ||
        location.startsWith('/register') ||
        location.startsWith('/admin/login') ||
        location.startsWith('/partner-with-us') ||
        location.startsWith('/saved-offers') ||
        location.startsWith('/followed-stores') ||
        location.startsWith('/notifications');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress(context, location);
      },
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
            surfaceTintColor: Colors.transparent,
            titleSpacing: isDetailRoute ? 0 : 12,
            leading: isDetailRoute
                ? IconButton(
                    icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back),
                    onPressed: () => _handleBackPress(context, location),
                  )
                : null,
            title: Row(
            children: [
              // Logo Area (Matching Angular .logo-area)
              InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.local_offer, color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr.get('app_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Single-Row Search Pill Trigger (Matching Angular .search-form & openSearchOverlay())
              Expanded(
                child: InkWell(
                  onTap: () {
                    SearchOverlayModal.show(context, initialQuery: _searchController.text);
                  },
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _searchController.text.isNotEmpty
                                ? _searchController.text
                                : (isRtl ? 'ابحث عن العروض، المتاجر...' : 'Search offers, stores, brands...'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _searchController.text.isNotEmpty
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.search, color: Color(0xFF64748B), size: 17),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            const SizedBox(width: 2),

            // Language Switcher Circle Button (Matching Angular .lang-toggle)
            InkWell(
              onTap: () {
                ref.read(translationProvider.notifier).toggleLanguage();
              },
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Text(
                    isRtl ? 'EN' : 'AR',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Header divider
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),

            Expanded(child: widget.child),
          ],
        ),

        // Bottom Navigation Bar (Matching Angular .mobile-bottom-nav)
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131C2E) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
              indicatorColor: isDark
                  ? const Color(0xFF16A34A).withOpacity(0.22)
                  : const Color(0xFFDCFCE7),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  );
                }
                return TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                );
              }),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(
                    color: Color(0xFF16A34A),
                    size: 22,
                  );
                }
                return IconThemeData(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  size: 22,
                );
              }),
            ),
            child: NavigationBar(
              height: 64,
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              elevation: 0,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: tr.get('home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.local_offer_outlined),
                  selectedIcon: const Icon(Icons.local_offer),
                  label: tr.get('offers'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront),
                  label: tr.get('stores'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories),
                  label: tr.get('flyers'),
                ),
                NavigationDestination(
                  icon: Icon(
                    authState.isAdminLoggedIn
                        ? Icons.security
                        : (authState.isLoggedIn ? Icons.account_circle_outlined : Icons.person_outline),
                  ),
                  selectedIcon: Icon(
                    authState.isAdminLoggedIn
                        ? Icons.security
                        : (authState.isLoggedIn ? Icons.account_circle : Icons.person),
                  ),
                  label: tr.get('profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

