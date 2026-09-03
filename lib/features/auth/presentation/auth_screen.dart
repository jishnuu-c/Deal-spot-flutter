import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/utils/translation_service.dart';

enum AuthScreenMode { login, register, admin }

class AuthScreen extends ConsumerStatefulWidget {
  final AuthScreenMode initialMode;
  final String returnUrl;

  const AuthScreen({
    super.key,
    required this.initialMode,
    required this.returnUrl,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late AuthScreenMode _mode;
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  int? _selectedCityId;

  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mode == AuthScreenMode.register && _selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your city')),
      );
      return;
    }

    setState(() => _submitting = true);

    final authNotifier = ref.read(authProvider.notifier);
    bool success = false;

    if (_mode == AuthScreenMode.login) {
      success = await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else if (_mode == AuthScreenMode.register) {
      success = await authNotifier.register(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _selectedCityId!,
      );
    } else if (_mode == AuthScreenMode.admin) {
      success = await authNotifier.adminLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        if (_mode == AuthScreenMode.admin) {
          context.go('/admin');
        } else {
          context.go(widget.returnUrl);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final authState = ref.watch(authProvider);
    final cities = ref.watch(cityRepositoryProvider).cities;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          actions: [
            TextButton(
              onPressed: () => ref.read(translationProvider.notifier).toggleLanguage(),
              child: Text(isRtl ? 'English' : 'عربي', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon & Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _mode == AuthScreenMode.admin
                              ? const Color(0xFFF59E0B).withOpacity(0.15)
                              : const Color(0xFF16A34A).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _mode == AuthScreenMode.admin ? Icons.admin_panel_settings : Icons.local_offer,
                          size: 40,
                          color: _mode == AuthScreenMode.admin ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _mode == AuthScreenMode.admin
                          ? tr.get('admin_login_title')
                          : (_mode == AuthScreenMode.login ? tr.get('login_title') : tr.get('register_title')),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _mode == AuthScreenMode.admin
                          ? tr.get('admin_login_subtitle')
                          : (_mode == AuthScreenMode.login ? tr.get('login_subtitle') : tr.get('register_subtitle')),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // Mode Switch Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _mode = AuthScreenMode.login),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _mode == AuthScreenMode.login ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _mode == AuthScreenMode.login
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Text(
                                  tr.get('login'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _mode == AuthScreenMode.login ? FontWeight.bold : FontWeight.normal,
                                    color: _mode == AuthScreenMode.login ? const Color(0xFF16A34A) : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _mode = AuthScreenMode.register),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _mode == AuthScreenMode.register ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _mode == AuthScreenMode.register
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Text(
                                  tr.get('register'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _mode == AuthScreenMode.register ? FontWeight.bold : FontWeight.normal,
                                    color: _mode == AuthScreenMode.register ? const Color(0xFF16A34A) : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _mode = AuthScreenMode.admin),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _mode == AuthScreenMode.admin ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _mode == AuthScreenMode.admin
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                                      : null,
                                ),
                                child: Text(
                                  isRtl ? 'المشرف' : 'Admin',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _mode == AuthScreenMode.admin ? FontWeight.bold : FontWeight.normal,
                                    color: _mode == AuthScreenMode.admin ? const Color(0xFFD97706) : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Box
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Full Name (Registration only)
                    if (_mode == AuthScreenMode.register) ...[
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: tr.get('full_name'),
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Full name is required' : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr.get('email'),
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Phone & City (Registration only)
                    if (_mode == AuthScreenMode.register) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: tr.get('phone'),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedCityId,
                        decoration: InputDecoration(
                          labelText: tr.get('city'),
                          prefixIcon: const Icon(Icons.place_outlined, size: 20),
                        ),
                        items: cities.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(isRtl ? c.nameAr : c.nameEn),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCityId = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Password Field (Login & Admin)
                    if (_mode != AuthScreenMode.register) ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: tr.get('password'),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 4 ? 'Password must be at least 4 chars' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mode == AuthScreenMode.admin ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _mode == AuthScreenMode.admin
                                  ? tr.get('admin_portal')
                                  : (_mode == AuthScreenMode.login ? tr.get('login') : tr.get('register')),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Partner with us Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/partner-with-us'),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.handshake_outlined, color: Color(0xFF16A34A), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.get('partner_with_us'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  Text(
                                    isRtl ? 'انشر عروض متجرك لآلاف المتسوقين' : 'Publish your store flyers & discounts',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
