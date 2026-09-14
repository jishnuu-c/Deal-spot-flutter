import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Material(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
            ),
          ),
        );
      },
    );
  },
);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final cityState = ref.watch(cityRepositoryProvider);

    final selectedCityName = cityState.selectedCity != null
        ? (isRtl ? cityState.selectedCity!.nameAr : cityState.selectedCity!.nameEn)
        : (isRtl ? 'جميع المدن' : 'All Cities');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              // 1. User Header / Guest Welcome Card (Matching Angular .sheet-header)
              if (authState.isLoggedIn)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: authState.isAdminLoggedIn
                              ? const Color(0xFFF59E0B).withOpacity(0.15)
                              : const Color(0xFF16A34A).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            authState.isAdminLoggedIn ? Icons.security : Icons.account_circle,
                            color: authState.isAdminLoggedIn ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    authState.currentUser?.fullName ?? tr.get('dealspot_customer'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (authState.isAdminLoggedIn) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      authState.currentAdmin?.role ?? 'ADMIN',
                                      style: const TextStyle(
                                        color: Color(0xFFD97706),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              authState.currentUser?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_circle_outlined, size: 48, color: Color(0xFF16A34A)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr.get('welcome_dealspot'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr.get('guest_welcome_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Guest Quick Action Buttons (Matching Angular .sheet-guest-actions)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.login, size: 16),
                              label: Text(
                                tr.get('login'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              onPressed: () => context.go('/login'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.person_add_outlined, size: 16),
                              label: Text(
                                tr.get('register'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              onPressed: () => context.go('/register'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // 2. Admin Control Panel Highlight (Matching Angular .sheet-group Administration)
              if (authState.isAdminLoggedIn) ...[
                _buildSectionHeader(tr.get('administration'), isDark),
                const SizedBox(height: 6),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    _buildSettingsTile(
                      icon: Icons.dashboard_rounded,
                      iconBgColor: const Color(0xFFF59E0B).withOpacity(0.18),
                      iconColor: const Color(0xFFD97706),
                      title: tr.get('admin_dashboard_control'),
                      subtitle: tr.get('admin_dashboard_desc'),
                      isDark: isDark,
                      isRtl: isRtl,
                      onTap: () => context.go('/admin'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // 3. My Activity Group (Matching Angular .sheet-group My Activity)
              if (authState.isLoggedIn) ...[
                _buildSectionHeader(tr.get('my_activity'), isDark),
                const SizedBox(height: 6),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    _buildSettingsTile(
                      icon: Icons.bookmark_rounded,
                      iconBgColor: const Color(0xFF16A34A).withOpacity(0.12),
                      iconColor: const Color(0xFF16A34A),
                      title: tr.get('saved_deals_offers'),
                      subtitle: tr.get('saved_deals_desc'),
                      isDark: isDark,
                      isRtl: isRtl,
                      onTap: () => context.go('/saved-offers'),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Icons.favorite_rounded,
                      iconBgColor: Colors.redAccent.withOpacity(0.12),
                      iconColor: Colors.redAccent,
                      title: tr.get('followed_stores'),
                      subtitle: tr.get('followed_stores_desc'),
                      isDark: isDark,
                      isRtl: isRtl,
                      onTap: () => context.go('/followed-stores'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // 4. Preferences & Partner Group (Matching Angular .sheet-group Preferences & Partner)
              _buildSectionHeader(tr.get('preferences_partner'), isDark),
              const SizedBox(height: 6),
              _buildCardGroup(
                isDark: isDark,
                children: [
                  // Selected City
                  _buildSettingsTile(
                    icon: Icons.place_rounded,
                    iconBgColor: const Color(0xFF16A34A).withOpacity(0.12),
                    iconColor: const Color(0xFF16A34A),
                    title: tr.get('selected_city'),
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        selectedCityName,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    isDark: isDark,
                    isRtl: isRtl,
                    onTap: () => _openCityModal(context, ref),
                  ),
                  _buildDivider(isDark),

                  // Language Switcher
                  _buildSettingsTile(
                    icon: Icons.language_rounded,
                    iconBgColor: const Color(0xFF3B82F6).withOpacity(0.12),
                    iconColor: const Color(0xFF3B82F6),
                    title: tr.get('language_field'),
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        isRtl ? 'العربية' : 'English',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    customTrailingIcon: Icons.swap_horiz,
                    isDark: isDark,
                    isRtl: isRtl,
                    onTap: () => ref.read(translationProvider.notifier).toggleLanguage(),
                  ),
                  _buildDivider(isDark),

                  // Partner With Us
                  _buildSettingsTile(
                    icon: Icons.handshake_rounded,
                    iconBgColor: const Color(0xFF10B981).withOpacity(0.12),
                    iconColor: const Color(0xFF10B981),
                    title: tr.get('partner_with_us_title'),
                    subtitle: tr.get('partner_with_us_subtitle'),
                    isDark: isDark,
                    isRtl: isRtl,
                    onTap: () => context.go('/partner-with-us'),
                  ),

                  // Admin Portal Access (for guest)
                  if (!authState.isLoggedIn) ...[
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Icons.admin_panel_settings_rounded,
                      iconBgColor: const Color(0xFFF59E0B).withOpacity(0.15),
                      iconColor: const Color(0xFFD97706),
                      title: tr.get('admin_portal_access'),
                      subtitle: tr.get('admin_portal_desc'),
                      isDark: isDark,
                      isRtl: isRtl,
                      onTap: () => context.go('/login?admin=true'),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 22),

              // 5. Logout Action (if logged in)
              if (authState.isLoggedIn) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    tr.get('logout'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/');
                  },
                ),
                const SizedBox(height: 20),
              ],

              // App Version footer
              Center(
                child: Text(
                  tr.get('app_version_tag'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.05,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildCardGroup({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailingWidget,
    IconData? customTrailingIcon,
    required bool isDark,
    required bool isRtl,
    required VoidCallback onTap,
  }) {
    final trailingIcon = customTrailingIcon ?? (isRtl ? Icons.chevron_left : Icons.chevron_right);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 19),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingWidget != null) ...[
            trailingWidget,
            const SizedBox(width: 4),
          ],
          Icon(trailingIcon, size: 18, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        ],
      ),
      onTap: onTap,
    );
  }
}

