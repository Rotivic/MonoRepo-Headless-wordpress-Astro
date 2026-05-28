import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.getToken);

  final Future<String?> Function() getToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Locale'] = 'es';

    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';

    handler.next(options);
  }
}
