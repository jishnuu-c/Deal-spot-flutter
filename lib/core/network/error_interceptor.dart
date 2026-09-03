import 'package:dio/dio.dart';
import '../services/storage_service.dart';

class ErrorInterceptor extends Interceptor {
  final StorageService _storageService;
  final Function()? onUnauthorized;

  ErrorInterceptor(this._storageService, {this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    if (response != null) {
      if ([401, 403].contains(response.statusCode)) {
        // Auto logout or redirect if unauthorized
        await _storageService.clearAuthData();
        if (onUnauthorized != null) {
          onUnauthorized!();
        }
      }
    }

    // Extract error message
    String errMsg = 'An unexpected error occurred';
    if (response != null && response.data is Map) {
      errMsg = response.data['message'] ?? response.statusMessage ?? errMsg;
    } else {
      errMsg = err.message ?? errMsg;
    }

    // Pass custom exception with custom message
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        type: err.type,
        error: errMsg,
      ),
    );
  }
}
