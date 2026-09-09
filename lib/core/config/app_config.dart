class AppConfig {
  // Matches Angular environment.ts:
  // apiUrl: 'http://192.168.1.110:8080/api/dealspot'
  // filePath: 'http://192.168.1.110:8080/'
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.110:8080/api/dealspot',
  );
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'http://192.168.1.110:8080',
  );
  static const String filePath = String.fromEnvironment(
    'FILE_PATH',
    defaultValue: 'http://192.168.1.110:8080/',
  );

  // App Identity & Hero Config (matches Angular APP_CONFIG)
  static const String appNameEn = 'DealSpot';
  static const String appNameAr = 'ديل سبوت';
  static const String appSubtitleEn = 'Saudi Arabia';
  static const String appSubtitleAr = 'المملكة العربية السعودية';
  static const String taglineEn =
      'Your premium Saudi discount and flyer platform. Save smart, live well.';
  static const String taglineAr =
      'منصتك المميزة للعروض والمنشورات الترويجية في المملكة. تسوق بذكاء ووفر أكثر.';
  static const String copyrightEn = '© 2026 DealSpot KSA. All rights reserved.';
  static const String copyrightAr =
      '© 2026 ديل سبوت السعودية. جميع الحقوق محفوظة.';

  static const String heroTitleEn = 'Discover the Best Deals & Flyers in';
  static const String heroTitleAr = 'اكتشف أفضل العروض والمنشورات في';
  static const String heroDescriptionEn =
      'Browse active discounts, store brochures, and coupon codes from hypermarkets, bookstores, restaurants, and electronics centers.';
  static const String heroDescriptionAr =
      'تصفح أحدث التخفيضات والعروض الترويجية والكتالوجات الأسبوعية وأكواد الخصم من كبرى المتاجر والمراكز التجارية.';
  static const String heroBannerBgImage = '/dealspot/hero_banner.png';

  static const String supportEmail = 'support@dealspot.sa';
  static const String adminDefaultEmail = 'admin@dealspot.com';

  /// Helper to resolve relative and absolute image URLs (matching Angular logic: filePath + uploads/ + url)
  static String normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    var trimmed = url.trim();
    if (trimmed == 'null' || trimmed == 'undefined') {
      return '';
    }
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:') ||
        trimmed.startsWith('assets/')) {
      return trimmed;
    }
    while (trimmed.startsWith('/')) {
      trimmed = trimmed.substring(1);
    }
    var base = filePath;
    if (!base.endsWith('/')) {
      base += '/';
    }

    if (!trimmed.startsWith('uploads/')) {
      trimmed = 'uploads/$trimmed';
    }

    return '$base$trimmed';
  }
}
