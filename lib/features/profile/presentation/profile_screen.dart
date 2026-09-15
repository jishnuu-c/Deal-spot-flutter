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

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sheet Drag Handle
                    Center(
                      child: Container(
                        width: 36,
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
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.place, color: Color(0xFF10B981), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              tr.get('select_city'),
                              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
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
                                    ? const Color(0xFF10B981).withOpacity(0.15)
                                    : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.public,
                                color: cityState.selectedCity == null ? const Color(0xFF10B981) : Colors.grey,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              isRtl ? 'جميع المدن' : 'All Cities',
                              style: TextStyle(
                                fontWeight: cityState.selectedCity == null ? FontWeight.bold : FontWeight.w500,
                                color: cityState.selectedCity == null ? const Color(0xFF10B981) : null,
                                fontSize: 14,
                              ),
                            ),
                            trailing: cityState.selectedCity == null
                                ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
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
                                      ? const Color(0xFF10B981).withOpacity(0.15)
                                      : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_city,
                                  color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                isRtl ? city.nameAr : city.nameEn,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF10B981) : null,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
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
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle (Matching Angular .sheet-drag-handle)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header (Matching Angular .sheet-header)
                  if (authState.isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: authState.isAdminLoggedIn
                                  ? const Color(0xFFF59E0B).withOpacity(0.15)
                                  : const Color(0xFF10B981).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                authState.isAdminLoggedIn ? Icons.security : Icons.account_circle,
                                color: authState.isAdminLoggedIn ? const Color(0xFFD97706) : const Color(0xFF10B981),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        authState.currentUser?.fullName ?? tr.get('dealspot_customer'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (authState.isAdminLoggedIn) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          authState.currentAdmin?.role ?? 'ADMIN',
                                          style: const TextStyle(
                                            color: Color(0xFFB45309),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  authState.currentUser?.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl ? 'مرحباً بك في ديل سبوت' : 'Welcome to DealSpot',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isRtl ? 'سجل الدخول لحفظ العروض والكتالوجات' : 'Sign in to save favorite deals & manage notifications',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                  // Body (Matching Angular .sheet-body)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Guest Quick Action Buttons (Matching Angular .sheet-guest-actions)
                        if (!authState.isLoggedIn) ...[
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    icon: const Icon(Icons.login, size: 16),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        isRtl ? 'تسجيل الدخول' : 'User Sign In',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                    onPressed: () => context.go('/login'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    icon: const Icon(Icons.person_add, size: 16),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        isRtl ? 'إنشاء حساب جديد' : 'Create New Account',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                    onPressed: () => context.go('/register'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Administration Group (Matching Angular .sheet-group Administration)
                        if (authState.isAdminLoggedIn) ...[
                          _buildSectionTitle(isRtl ? 'لوحة الإدارة' : 'ADMINISTRATION', isDark),
                          const SizedBox(height: 6),
                          _buildSheetItem(
                            icon: Icons.dashboard,
                            iconBg: const Color(0xFFF59E0B).withOpacity(0.18),
                            iconColor: const Color(0xFFD97706),
                            title: isRtl ? 'لوحة تحكم المسؤول' : 'Admin Dashboard & Control',
                            subtitle: isRtl ? 'إدارة العروض، المتاجر، الأقسام والمستخدمين' : 'Manage offers, stores, categories & users',
                            isDark: isDark,
                            isRtl: isRtl,
                            onTap: () => context.go('/admin'),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // My Activity Group (Matching Angular .sheet-group My Activity)
                        if (authState.isLoggedIn) ...[
                          _buildSectionTitle(isRtl ? 'نشاطي' : 'MY ACTIVITY', isDark),
                          const SizedBox(height: 6),
                          _buildSheetItem(
                            icon: Icons.bookmark,
                            iconBg: const Color(0xFF10B981).withOpacity(0.12),
                            iconColor: const Color(0xFF10B981),
                            title: isRtl ? 'العروض والخصومات المحفوظة' : 'Saved Deals & Offers',
                            isDark: isDark,
                            isRtl: isRtl,
                            onTap: () => context.go('/saved-offers'),
                          ),
                          const SizedBox(height: 8),
                          _buildSheetItem(
                            icon: Icons.favorite,
                            iconBg: Colors.redAccent.withOpacity(0.12),
                            iconColor: Colors.redAccent,
                            title: isRtl ? 'المتاجر المتابعة' : 'Followed Stores',
                            isDark: isDark,
                            isRtl: isRtl,
                            onTap: () => context.go('/followed-stores'),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Preferences & Partner Tools (Matching Angular .sheet-group Preferences & Partner)
                        _buildSectionTitle(isRtl ? 'التفضيلات والشراكة' : 'PREFERENCES & PARTNER', isDark),
                        const SizedBox(height: 6),

                        // Selected City
                        _buildSheetItem(
                          icon: Icons.place,
                          iconBg: const Color(0xFF10B981).withOpacity(0.12),
                          iconColor: const Color(0xFF10B981),
                          title: isRtl ? 'المدينة الحالية' : 'Selected City',
                          badgeText: selectedCityName,
                          isDark: isDark,
                          isRtl: isRtl,
                          onTap: () => _openCityModal(context, ref),
                        ),
                        const SizedBox(height: 8),

                        // Language Switcher
                        _buildSheetItem(
                          icon: Icons.language,
                          iconBg: const Color(0xFF3B82F6).withOpacity(0.12),
                          iconColor: const Color(0xFF3B82F6),
                          title: isRtl ? 'اللغة / Language' : 'Language / اللغة',
                          badgeText: isRtl ? 'English' : 'العربية',
                          trailingIcon: Icons.swap_horiz,
                          isDark: isDark,
                          isRtl: isRtl,
                          onTap: () => ref.read(translationProvider.notifier).toggleLanguage(),
                        ),
                        const SizedBox(height: 8),

                        // Partner With Us
                        _buildSheetItem(
                          icon: Icons.handshake,
                          iconBg: const Color(0xFF10B981).withOpacity(0.12),
                          iconColor: const Color(0xFF10B981),
                          title: isRtl ? 'انضم كشريك (سجل متجرك)' : 'Partner With Us (Register Store)',
                          isDark: isDark,
                          isRtl: isRtl,
                          onTap: () => context.go('/partner-with-us'),
                        ),

                        // Admin Portal Access (for guest)
                        if (!authState.isLoggedIn) ...[
                          const SizedBox(height: 8),
                          _buildSheetItem(
                            icon: Icons.admin_panel_settings,
                            iconBg: const Color(0xFFF59E0B).withOpacity(0.15),
                            iconColor: const Color(0xFFD97706),
                            title: isRtl ? 'بوابة المسؤولين' : 'Admin Portal Access',
                            isDark: isDark,
                            isRtl: isRtl,
                            onTap: () => context.go('/login?admin=true'),
                          ),
                        ],

                        // Log Out Button (if logged in)
                        if (authState.isLoggedIn) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.logout, size: 18),
                              label: Text(
                                isRtl ? 'تسجيل الخروج' : 'Log Out',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              onPressed: () {
                                ref.read(authProvider.notifier).logout();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr.get('logout_success'))),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSheetItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? badgeText,
    IconData? trailingIcon,
    required bool isDark,
    required bool isRtl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Optional Badge
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],

            const SizedBox(width: 6),

            // Arrow
            Icon(
              trailingIcon ?? (isRtl ? Icons.chevron_left : Icons.chevron_right),
              size: 18,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
