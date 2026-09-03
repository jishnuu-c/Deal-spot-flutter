import 'package:dio/dio.dart';
import '../services/storage_service.dart';

class JwtInterceptor extends Interceptor {
  final StorageService _storageService;

  JwtInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();
    
    // Only intercept requests targeting our REST API (/api)
    if (token != null && options.path.contains('/api')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }
}
