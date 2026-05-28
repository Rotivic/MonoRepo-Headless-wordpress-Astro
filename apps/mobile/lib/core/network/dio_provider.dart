// lib/core/network/dio_provider.dart
import 'package:dio/dio.dart';
import 'package:tcg_platform_mobile/core/network/auth_interceptor.dart';
import 'package:tcg_platform_mobile/core/network/logging_interceptor.dart';

class DioProvider {
  static Dio create(
    BaseOptions options, {
    required Future<String?> Function() tokenProvider,
  }) {
    final dio = Dio(options);

    dio.interceptors.add(AuthInterceptor(tokenProvider));
    dio.interceptors.add(AppLoggingInterceptor());

    return dio;
  }
}
