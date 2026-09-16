import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
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
  final _confirmPasswordController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  int? _selectedCityId;

  bool _showLoginPass = false;
  bool _showRegPass = false;
  bool _showRegConfirmPass = false;
  bool _showAdminPass = false;

  bool _submitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _adminEmailController.text = AppConfig.adminDefaultEmail;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthScreenMode newMode) {
    setState(() {
      _mode = newMode;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mode == AuthScreenMode.register && _selectedCityId == null) {
      setState(() {
        final isAr = ref.read(translationProvider) == AppLanguage.ar;
        _errorMessage = isAr ? 'يرجى اختيار مدينتك.' : 'Please select your city.';
      });
      return;
    }

    if (_mode == AuthScreenMode.register &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        final isAr = ref.read(translationProvider) == AppLanguage.ar;
        _errorMessage = isAr ? 'كلمات المرور غير متطابقة.' : 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final isAr = ref.read(translationProvider) == AppLanguage.ar;
    bool success = false;

    try {
      if (_mode == AuthScreenMode.login) {
        success = await authNotifier.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (success) {
          final user = ref.read(authProvider).currentUser;
          final admin = ref.read(authProvider).currentAdmin;
          final name = user?.fullName ?? admin?.fullName ?? '';
          _successMessage = isAr
              ? (name.isNotEmpty ? 'أهلاً بك مجدداً، $name!' : 'تم تسجيل الدخول بنجاح!')
              : (name.isNotEmpty ? 'Welcome back, $name!' : 'Login Successful!');
        } else {
          _errorMessage = ref.read(authProvider).error ??
              (isAr ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة' : 'Invalid email or password');
        }
      } else if (_mode == AuthScreenMode.register) {
        success = await authNotifier.register(
          _fullNameController.text.trim(),
          _emailController.text.trim(),
          _phoneController.text.trim(),
          _selectedCityId!,
          password: _passwordController.text.isNotEmpty ? _passwordController.text : 'Password@123',
        );
        if (success) {
          final user = ref.read(authProvider).currentUser;
          final name = user?.fullName ?? '';
          _successMessage = isAr
              ? (name.isNotEmpty ? 'تم إنشاء الحساب بنجاح! أهلاً بك، $name!' : 'تم إنشاء الحساب بنجاح!')
              : (name.isNotEmpty ? 'Account created! Welcome, $name!' : 'Account created successfully!');
        } else {
          _errorMessage = ref.read(authProvider).error ??
              (isAr
                  ? 'فشل إنشاء الحساب. قد يكون البريد الإلكتروني مسجلاً مسبقاً.'
                  : 'Registration failed. Email may already be in use.');
        }
      } else if (_mode == AuthScreenMode.admin) {
        success = await authNotifier.adminLogin(
          _adminEmailController.text.trim(),
          _adminPasswordController.text,
        );
        if (success) {
          final admin = ref.read(authProvider).currentAdmin;
          final name = admin?.fullName ?? '';
          _successMessage = isAr
              ? (name.isNotEmpty ? 'تم تسجيل الدخول بنجاح! مرحباً $name' : 'تم تسجيل دخول المسؤول بنجاح. جاري التحويل...')
              : (name.isNotEmpty ? 'Login Successful! Welcome, $name!' : 'Admin authentication successful. Redirecting...');
        } else {
          _errorMessage = ref.read(authProvider).error ??
              (isAr
                  ? 'بيانات المسؤول غير صحيحة أو الحساب غير مفعّل'
                  : 'Invalid admin credentials or account is inactive');
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    if (mounted) {
      setState(() => _submitting = false);
      if (success && _successMessage != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Keep message visible for 800ms before navigating (matching Angular setTimeout)
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          final authState = ref.read(authProvider);
          if (_mode == AuthScreenMode.admin || authState.isAdminLoggedIn) {
            final target = (widget.returnUrl.startsWith('/admin')) ? widget.returnUrl : '/admin';
            context.go(target);
          } else {
            final target = (widget.returnUrl.isNotEmpty &&
                    widget.returnUrl != '/login' &&
                    widget.returnUrl != '/register')
                ? widget.returnUrl
                : '/';
            context.go(target);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final cities = ref.watch(cityRepositoryProvider).cities;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryGreen = const Color(0xFF10B981);
    final adminAmber = const Color(0xFFD97706);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.8),
            radius: 1.2,
            colors: [
              primaryGreen.withOpacity(isDark ? 0.08 : 0.06),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
                    blurRadius: 35,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header: Badge Pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? primaryGreen.withOpacity(0.15)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer, size: 15, color: primaryGreen),
                            const SizedBox(width: 6),
                            Text(
                              isRtl ? AppConfig.appNameAr : AppConfig.appNameEn,
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Headline
                    if (_mode == AuthScreenMode.login)
                      Text(
                        isRtl ? 'مرحباً بك مجدداً!' : 'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      )
                    else if (_mode == AuthScreenMode.register)
                      Text(
                        isRtl ? 'إنشاء حساب جديد' : 'Create Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, color: adminAmber, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            isRtl ? 'بوابة الإشراف والإدارة' : 'Admin Portal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: adminAmber,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),

                    // Subline
                    Text(
                      _mode == AuthScreenMode.login
                          ? (isRtl
                              ? 'سجل الدخول للوصول إلى عروضك المحفوظة ومتاجرك المفضلة.'
                              : 'Sign in to access your saved deals, favorite stores, and tailored discounts.')
                          : (_mode == AuthScreenMode.register
                              ? (isRtl
                                  ? 'انضم إلى ديل سبوت لاكتشاف الكتالوجات الأسبوعية وحفظ أفضل العروض.'
                                  : 'Join DealSpot to discover weekly flyers, save favorite offers, and more.')
                              : (isRtl
                                  ? 'منطقة وصول مخصصة لمدراء المتاجر والمشرفين على المنصة.'
                                  : 'Secure authentication area for store managers and platform administrators.')),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: _mode == AuthScreenMode.admin
                            ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mode Navigation Tabs (3-Segment Switcher)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(
                            title: isRtl ? 'دخول المستخدم' : 'User Login',
                            icon: Icons.login,
                            isActive: _mode == AuthScreenMode.login,
                            activeColor: primaryGreen,
                            isDark: isDark,
                            onTap: () => _switchMode(AuthScreenMode.login),
                          ),
                          const SizedBox(width: 4),
                          _buildTabButton(
                            title: isRtl ? 'حساب جديد' : 'Sign Up',
                            icon: Icons.person_add_alt_1,
                            isActive: _mode == AuthScreenMode.register,
                            activeColor: primaryGreen,
                            isDark: isDark,
                            onTap: () => _switchMode(AuthScreenMode.register),
                          ),
                          const SizedBox(width: 4),
                          _buildTabButton(
                            title: isRtl ? 'لوحة الإدارة' : 'Admin Portal',
                            icon: Icons.admin_panel_settings_outlined,
                            isActive: _mode == AuthScreenMode.admin,
                            activeColor: adminAmber,
                            isDark: isDark,
                            onTap: () => _switchMode(AuthScreenMode.admin),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Error Alert Box
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Success Alert Box
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B).withOpacity(0.4) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ==========================================
                    // FORM 1: USER LOGIN
                    // ==========================================
                    if (_mode == AuthScreenMode.login) ...[
                      _buildInputLabel(isRtl ? 'البريد الإلكتروني' : 'Email Address', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: 'name@example.com',
                          prefixIcon: Icons.mail_outline,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isRtl ? 'يرجى إدخال البريد الإلكتروني.' : 'Please enter a valid email address.';
                          }
                          if (!value.contains('@')) {
                            return isRtl ? 'يرجى إدخال بريد إلكتروني صحيح.' : 'Please enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel(isRtl ? 'كلمة المرور' : 'Password', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showLoginPass,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _buildInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showLoginPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _showLoginPass = !_showLoginPass),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 4) {
                            return isRtl
                                ? 'كلمة المرور يجب ألا تقل عن 6 أحرف.'
                                : 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: _buildSubmitButtonStyle(primaryGreen),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isRtl ? 'تسجيل الدخول' : 'Sign In',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 18),

                      // Bottom Switch
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isRtl ? 'ليس لديك حساب؟' : "Don't have an account?",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 5),
                              InkWell(
                                onTap: () => _switchMode(AuthScreenMode.register),
                                child: Text(
                                  isRtl ? 'سجل الآن' : 'Sign Up',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _switchMode(AuthScreenMode.admin),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 15, color: Color(0xFFB45309)),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    isRtl
                                        ? 'هل أنت مسؤول أو مدير متجر؟'
                                        : 'Are you an administrator or store manager?',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ==========================================
                    // FORM 2: USER REGISTER
                    // ==========================================
                    if (_mode == AuthScreenMode.register) ...[
                      _buildInputLabel(isRtl ? 'الاسم الكامل' : 'Full Name', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: isRtl ? 'أحمد العتيبي' : 'Ahmed Al-Otaibi',
                          prefixIcon: Icons.badge_outlined,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return isRtl
                                ? 'الاسم يجب أن يحتوي على 3 أحرف على الأقل.'
                                : 'Name must be at least 3 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel(isRtl ? 'البريد الإلكتروني' : 'Email Address', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: 'name@example.com',
                          prefixIcon: Icons.mail_outline,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return isRtl ? 'البريد الإلكتروني مطلوب.' : 'Valid email required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel(isRtl ? 'رقم الجوال' : 'Mobile Phone', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: '0501234567',
                          prefixIcon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 8) {
                            return isRtl ? 'رقم الجوال غير صحيح.' : 'Valid phone number required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel(isRtl ? 'المدينة الرئيسية' : 'Primary City', isDark),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<int>(
                        value: _selectedCityId,
                        decoration: _buildInputDecoration(
                          hintText: isRtl ? 'اختر مدينتك' : 'Select your city',
                          prefixIcon: Icons.place_outlined,
                          isDark: isDark,
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: cities.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(
                              isRtl ? c.nameAr : c.nameEn,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCityId = val),
                        validator: (val) => val == null
                            ? (isRtl ? 'يرجى اختيار مدينتك.' : 'Please select your city.')
                            : null,
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel(isRtl ? 'كلمة المرور' : 'Password', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showRegPass,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showRegPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _showRegPass = !_showRegPass),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return isRtl ? '6 خانات على الأقل.' : 'Min 6 chars.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel(isRtl ? 'تأكيد كلمة المرور' : 'Confirm Password', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_showRegConfirmPass,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _buildInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_clock_outlined,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showRegConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _showRegConfirmPass = !_showRegConfirmPass),
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return isRtl ? 'كلمات المرور غير متطابقة.' : 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: _buildSubmitButtonStyle(primaryGreen),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isRtl ? 'إتمام التسجيل' : 'Complete Registration',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 18),

                      // Bottom Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isRtl ? 'لديك حساب بالفعل؟' : 'Already have an account?',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () => _switchMode(AuthScreenMode.login),
                            child: Text(
                              isRtl ? 'تسجيل الدخول' : 'Sign In',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ==========================================
                    // FORM 3: ADMIN ACCESS PORTAL
                    // ==========================================
                    if (_mode == AuthScreenMode.admin) ...[
                      // Admin Notice Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF451A03).withOpacity(0.35) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user_outlined, color: adminAmber, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRtl ? 'منطقة إشراف محمية' : 'Restricted Administration Area',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isRtl
                                        ? 'يرجى تسجيل الدخول بحساب المسؤول المخول لإدارة العروض، المتاجر، الأقسام والكتالوجات.'
                                        : 'Please use your authorized administrator credentials to manage offers, stores, categories, and system catalogs.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.4,
                                      color: isDark ? Colors.white70 : const Color(0xFF78350F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildInputLabel(isRtl ? 'بريد المسؤول / المشرف' : 'Admin / Staff Email', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _adminEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(
                          hintText: AppConfig.adminDefaultEmail,
                          prefixIcon: Icons.admin_panel_settings_outlined,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isRtl ? 'البريد الإلكتروني للمسؤول مطلوب.' : 'Admin email is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel(isRtl ? 'رمز مرور الإدارة' : 'Admin Password', isDark),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _adminPasswordController,
                        obscureText: !_showAdminPass,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _buildInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.vpn_key_outlined,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showAdminPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _showAdminPass = !_showAdminPass),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isRtl ? 'كلمة المرور مطلوبة.' : 'Password is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: _buildSubmitButtonStyle(adminAmber),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.dashboard_customize_outlined, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    isRtl ? 'تسجيل الدخول وفتح لوحة الإدارة' : 'Authorize & Open Admin Panel',
                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 18),

                      // Return to User Login Link
                      Center(
                        child: InkWell(
                          onTap: () => _switchMode(AuthScreenMode.login),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRtl ? Icons.arrow_forward : Icons.arrow_back,
                                size: 16,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isRtl ? 'العودة لتسجيل دخول المستخدم' : 'Return to User Sign In',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? activeColor
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive
                        ? activeColor
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(prefixIcon, size: 19, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
    );
  }

  ButtonStyle _buildSubmitButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: color.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
