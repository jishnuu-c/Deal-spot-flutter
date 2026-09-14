import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/notification_repository.dart';
import '../../../core/utils/translation_service.dart';

class PublicLayout extends ConsumerStatefulWidget {
  final Widget child;

  const PublicLayout({super.key, required this.child});

  @override
  ConsumerState<PublicLayout> createState() => _PublicLayoutState();
}

class _PublicLayoutState extends ConsumerState<PublicLayout> {
  final TextEditingController _searchController = TextEditingController();

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/offers')) return 1;
    if (location.startsWith('/flyers')) return 2;
    if (location.startsWith('/stores')) return 3;
    if (location.startsWith('/profile') ||
        location.startsWith('/saved-offers') ||
        location.startsWith('/followed-stores') ||
        location.startsWith('/partner-with-us')) return 4;
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
        context.go('/flyers');
        break;
      case 3:
        context.go('/stores');
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
    final isDetailRoute = location.contains(RegExp(r'/(offers|stores|flyers|products)/\d+')) ||
        location.startsWith('/categories/') ||
        location.endsWith('/branches');
    final canPop = context.canPop();

    return Directionality(
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
                  onPressed: () {
                    if (canPop) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                )
              : null,
          title: InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.local_offer, color: Colors.white, size: 15),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr.get('app_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                          letterSpacing: -0.3,
                          color: Color(0xFF16A34A),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        isRtl ? 'المملكة العربية السعودية' : 'Saudi Arabia',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // City Selector Pill Button (Matching Angular .city-selector)
            InkWell(
              onTap: () => _openCityModal(context, ref),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, color: Color(0xFF16A34A), size: 13),
                    const SizedBox(width: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 58),
                      child: Text(
                        cityState.selectedCity != null
                            ? (isRtl ? cityState.selectedCity!.nameAr : cityState.selectedCity!.nameEn)
                            : (isRtl ? 'جميع المدن' : 'All Cities'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Language Switcher Pill (Matching Angular .lang-toggle)
            InkWell(
              onTap: () {
                ref.read(translationProvider.notifier).toggleLanguage();
              },
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  isRtl ? 'EN' : 'عربي',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),

            // Admin Direct Entry (if admin logged in)
            if (authState.isAdminLoggedIn)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFF59E0B), size: 19),
                tooltip: tr.get('admin_panel'),
                onPressed: () => context.go('/admin'),
              ),

            // Notifications Bell
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Badge(
                label: unreadCount > 0 ? Text('$unreadCount', style: const TextStyle(fontSize: 9)) : null,
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.redAccent,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              onPressed: () => context.go('/notifications'),
            ),
            const SizedBox(width: 4),
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

            // Sticky Search Bar on Home Tab (Matching Angular search-form)
            if (selectedIndex == 0)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      context.go('/offers?search=${Uri.encodeComponent(query.trim())}');
                    }
                  },
                  decoration: InputDecoration(
                    hintText: isRtl ? 'ابحث عن العروض، المتاجر، الماركات...' : 'Search offers, stores, brands...',
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF16A34A), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                    ),
                  ),
                ),
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
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories),
                  label: tr.get('flyers'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront),
                  label: tr.get('stores'),
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
    );
  }
}

