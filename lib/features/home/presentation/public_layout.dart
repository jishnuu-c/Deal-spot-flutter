import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/notification_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

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

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          tr.get('select_city'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr.get('select_city_desc'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cityState.cities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final city = cityState.cities[index];
                    final isSelected = city.id == cityState.selectedCity?.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF16A34A).withOpacity(0.15) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: isSelected ? const Color(0xFF16A34A) : Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        isRtl ? city.nameAr : city.nameEn,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF16A34A) : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
                          : null,
                      onTap: () {
                        ref.read(cityRepositoryProvider.notifier).selectCity(city);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
          titleSpacing: 8,
          title: InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.local_offer, color: Colors.white, size: 16),
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
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          tr.get('app_subtitle'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // City Selector Pill Button
            InkWell(
              onTap: () => _openCityModal(context, ref),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, color: Color(0xFF16A34A), size: 14),
                    const SizedBox(width: 3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 60),
                      child: Text(
                        cityState.selectedCity != null
                            ? (isRtl ? cityState.selectedCity!.nameAr : cityState.selectedCity!.nameEn)
                            : tr.get('all_cities'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Language Switcher
            InkWell(
              onTap: () {
                ref.read(translationProvider.notifier).toggleLanguage();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  isRtl ? 'EN' : 'عربي',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A), fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 2),

            // Admin Direct Entry (if admin logged in)
            if (authState.isAdminLoggedIn)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFF59E0B), size: 20),
                tooltip: tr.get('admin_panel'),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () => context.go('/admin'),
              ),

            // Notifications
            IconButton(
              icon: Badge(
                label: unreadCount > 0 ? Text('$unreadCount') : null,
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.notifications_none_outlined, size: 20),
              ),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: () => context.go('/notifications'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Sticky Search Bar on Main Public Views
            if (selectedIndex < 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF16A34A), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                    ),
                  ),
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
          indicatorColor: const Color(0xFF16A34A).withOpacity(0.18),
          elevation: 8,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: Color(0xFF16A34A)),
              label: tr.get('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_offer_outlined),
              selectedIcon: const Icon(Icons.local_offer, color: Color(0xFF16A34A)),
              label: tr.get('offers'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book, color: Color(0xFF16A34A)),
              label: tr.get('flyers'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront, color: Color(0xFF16A34A)),
              label: tr.get('stores'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person, color: Color(0xFF16A34A)),
              label: tr.get('profile'),
            ),
          ],
        ),
      ),
    );
  }
}
