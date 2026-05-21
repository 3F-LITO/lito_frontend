import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  static Dio get instance {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        // Tangkap error jika Django mati atau internet putus
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            type: DioExceptionType.connectionError,
            message: 'OFFLINE_MODE',
          ));
        } else {
          handler.next(error);
        }
      },
    ));

    return dio;
  }
}
