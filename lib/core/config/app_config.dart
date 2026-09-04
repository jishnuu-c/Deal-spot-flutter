class AppConfig {
  // Matches Angular environment.ts:
  // apiUrl: 'http://192.168.1.110:8080/api/dealspot'
  // filePath: 'http://192.168.1.110:8080/'
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.110:8080/api/dealspot',
  );
  //   'API_URL',
  //   defaultValue: 'http://103.199.210.172:8080/api/dealspot',
  // );
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'http://192.168.1.110:8080',
  );
  //   'SERVER_URL',
  //   defaultValue: 'http://192.168.1.110:8080',
  // );
  static const String filePath = String.fromEnvironment(
    'FILE_PATH',
    defaultValue: 'http://192.168.1.110:8080/',
  );
  //   'FILE_PATH',
  //   defaultValue: 'http://103.199.210.172:8080/',
  // );

  /// Helper to resolve relative and absolute image URLs (matching Angular logic: filePath + url)
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
        trimmed.startsWith('data:')) {
      return trimmed;
    }
    while (trimmed.startsWith('/')) {
      trimmed = trimmed.substring(1);
    }
    var base = filePath;
    if (!base.endsWith('/')) {
      base += '/';
    }
    return '$base$trimmed';
  }
}
