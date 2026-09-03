import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const String keyToken = 'dealspot_token';
  static const String keyUser = 'dealspot_user';
  static const String keyAdminToken = 'dealspot_admin_token';
  static const String keyAdminUser = 'dealspot_admin_user';

  Future<void> saveToken(String token) async {
    await _storage.write(key: keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: keyToken);
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: keyUser, value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: keyUser);
  }

  Future<void> saveAdminToken(String token) async {
    await _storage.write(key: keyAdminToken, value: token);
  }

  Future<String?> getAdminToken() async {
    return await _storage.read(key: keyAdminToken);
  }

  Future<void> saveAdminUser(String adminJson) async {
    await _storage.write(key: keyAdminUser, value: adminJson);
  }

  Future<String?> getAdminUser() async {
    return await _storage.read(key: keyAdminUser);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: keyToken);
    await _storage.delete(key: keyUser);
    await _storage.delete(key: keyAdminToken);
    await _storage.delete(key: keyAdminUser);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
