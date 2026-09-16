import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiClient {
  final Dio dio;
  final StorageService _storageService;

  static String get cleanBaseUrl {
    var url = AppConfig.baseUrl.trim();
    if (!url.endsWith('/')) {
      url += '/';
    }
    return url;
  }

  static String normalizePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    var p = path.trim();
    while (p.startsWith('/')) {
      p = p.substring(1);
    }
    return p;
  }

  ApiClient(this._storageService)
      : dio = Dio(
          BaseOptions(
            baseUrl: cleanBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final adminToken = await _storageService.getAdminToken();
          final userToken = await _storageService.getToken();
          final token = (adminToken != null && adminToken.isNotEmpty)
              ? adminToken
              : userToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Log or handle errors globally if needed
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(normalizePath(path), queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(normalizePath(path), data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.put<T>(normalizePath(path), data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.patch<T>(normalizePath(path), data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.delete<T>(normalizePath(path), data: data, queryParameters: queryParameters, options: options);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});
