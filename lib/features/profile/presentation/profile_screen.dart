import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.get('profile'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: authState.isLoggedIn
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // User Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF16A34A).withOpacity(0.15),
                            child: const Icon(Icons.person, size: 44, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            authState.currentUser?.fullName ?? 'DealSpot Customer',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authState.currentUser?.email ?? '',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                          ),
                          if (authState.isAdminLoggedIn) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                authState.currentAdmin?.role ?? 'ADMIN',
                                style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Options List Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bookmark, color: Color(0xFF16A34A), size: 20),
                            ),
                            title: Text(tr.get('saved_offers'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                            onTap: () => context.go('/saved-offers'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                            ),
                            title: Text(tr.get('followed_stores'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                            onTap: () => context.go('/followed-stores'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.handshake_outlined, color: Color(0xFF16A34A), size: 20),
                            ),
                            title: Text(tr.get('partner_with_us'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                            onTap: () => context.go('/partner-with-us'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.language, color: Color(0xFF3B82F6), size: 20),
                            ),
                            title: const Text('Language / اللغة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: Text(
                              isRtl ? 'العربية (AR)' : 'English (EN)',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13),
                            ),
                            onTap: () => ref.read(translationProvider.notifier).toggleLanguage(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Admin Access Card (if Admin)
                    if (authState.isAdminLoggedIn) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.dashboard_outlined, color: Color(0xFFD97706)),
                          title: Text(
                            isRtl ? 'لوحة التحكم والإدارة' : 'Admin Control Panel',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFFD97706)),
                          onTap: () => context.go('/admin'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(tr.get('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/');
                        },
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_circle_outlined, size: 64, color: Color(0xFF16A34A)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRtl ? 'مرحباً بك في ديل سبوت' : 'Welcome to DealSpot',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRtl ? 'سجل الدخول لحفظ العروض والكتالوجات وتلقي التنبيهات' : 'Sign in to access your saved offers, followed stores, and alerts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.login, size: 18),
                        label: Text(tr.get('login'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () => context.go('/login'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: Text(tr.get('register'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () => context.go('/register'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Partner with us
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      leading: const Icon(Icons.handshake_outlined, color: Color(0xFF16A34A)),
                      title: Text(tr.get('partner_with_us'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.go('/partner-with-us'),
                    ),
                    const SizedBox(height: 10),

                    // Admin Portal Entry
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFD97706)),
                      title: Text(tr.get('admin_portal'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.go('/login?admin=true'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
