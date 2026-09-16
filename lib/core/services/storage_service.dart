import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String keyToken = 'dealspot_token';
  static const String keyUser = 'dealspot_user';
  static const String keyAdminToken = 'dealspot_admin_token';
  static const String keyAdminUser = 'dealspot_admin_user';

  // In-memory cache for ultra-fast access
  String? _cachedToken;
  String? _cachedUser;
  String? _cachedAdminToken;
  String? _cachedAdminUser;

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _storage.write(key: keyToken, value: token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: keyToken);
    return _cachedToken;
  }

  Future<void> saveUser(String userJson) async {
    _cachedUser = userJson;
    _storage.write(key: keyUser, value: userJson);
  }

  Future<String?> getUser() async {
    if (_cachedUser != null) return _cachedUser;
    _cachedUser = await _storage.read(key: keyUser);
    return _cachedUser;
  }

  Future<void> saveAdminToken(String token) async {
    _cachedAdminToken = token;
    _storage.write(key: keyAdminToken, value: token);
  }

  Future<String?> getAdminToken() async {
    if (_cachedAdminToken != null) return _cachedAdminToken;
    _cachedAdminToken = await _storage.read(key: keyAdminToken);
    return _cachedAdminToken;
  }

  Future<void> saveAdminUser(String adminJson) async {
    _cachedAdminUser = adminJson;
    _storage.write(key: keyAdminUser, value: adminJson);
  }

  Future<String?> getAdminUser() async {
    if (_cachedAdminUser != null) return _cachedAdminUser;
    _cachedAdminUser = await _storage.read(key: keyAdminUser);
    return _cachedAdminUser;
  }

  void saveAdminSession({
    required String token,
    required String adminJson,
    required String userJson,
  }) {
    _cachedAdminToken = token;
    _cachedAdminUser = adminJson;
    _cachedToken = token;
    _cachedUser = userJson;

    // Parallel background write without blocking UI thread
    Future.wait([
      _storage.write(key: keyAdminToken, value: token),
      _storage.write(key: keyAdminUser, value: adminJson),
      _storage.write(key: keyToken, value: token),
      _storage.write(key: keyUser, value: userJson),
    ]);
  }

  void saveUserSession({
    required String token,
    required String userJson,
    String? adminJson,
  }) {
    _cachedToken = token;
    _cachedUser = userJson;
    final writes = <Future>[
      _storage.write(key: keyToken, value: token),
      _storage.write(key: keyUser, value: userJson),
    ];

    if (adminJson != null) {
      _cachedAdminToken = token;
      _cachedAdminUser = adminJson;
      writes.add(_storage.write(key: keyAdminToken, value: token));
      writes.add(_storage.write(key: keyAdminUser, value: adminJson));
    }

    // Parallel background write without blocking UI thread
    Future.wait(writes);
  }

  Future<void> clearAuthData() async {
    _cachedToken = null;
    _cachedUser = null;
    _cachedAdminToken = null;
    _cachedAdminUser = null;

    try {
      await Future.wait([
        _storage.delete(key: keyToken),
        _storage.delete(key: keyUser),
        _storage.delete(key: keyAdminToken),
        _storage.delete(key: keyAdminUser),
      ]);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
