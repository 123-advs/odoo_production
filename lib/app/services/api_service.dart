import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late final Dio dio;

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.odooBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(_AuthInterceptor());
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = await Get.find<StorageService>().readSessionId();
    if (session != null) {
      options.headers['Cookie'] = 'session_id=$session';
    }
    handler.next(options);
  }
}
