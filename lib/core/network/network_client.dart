import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';
import 'jwt_interceptor.dart';
import 'error_interceptor.dart';

class NetworkClient {
  final StorageService _storageService;
  late final Dio dio;

  NetworkClient(this._storageService, {Function()? onUnauthorized}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      JwtInterceptor(_storageService),
      ErrorInterceptor(_storageService, onUnauthorized: onUnauthorized),
      LogInterceptor(requestBody: true, responseBody: true), // useful for debugging API calls
    ]);
  }
}
