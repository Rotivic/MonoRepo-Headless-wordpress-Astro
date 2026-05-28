import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppLoggingInterceptor extends Interceptor {
  AppLoggingInterceptor({
    this.enabled = kDebugMode,
    this.maxBodyChars = 2000,
  });

  final bool enabled;
  final int maxBodyChars;

  static const _sensitiveKeys = {
    'password',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'cookie',
    'set-cookie',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);

    options.extra['_ts'] = DateTime.now().millisecondsSinceEpoch;

    dev.log('-> ${options.method} ${options.uri}', name: 'network');

    if (options.data != null) {
      dev.log('body: ${_truncate(_sanitize(options.data))}', name: 'network');
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!enabled) return handler.next(response);

    final req = response.requestOptions;
    final start =
        (req.extra['_ts'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
    final ms = DateTime.now().millisecondsSinceEpoch - start;

    dev.log(
      '<- [${response.statusCode}] ($ms ms) ${req.method} ${req.uri}',
      name: 'network',
    );
    dev.log('data: ${_truncate(_sanitize(response.data))}', name: 'network');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) return handler.next(err);

    final req = err.requestOptions;
    final start =
        (req.extra['_ts'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
    final ms = DateTime.now().millisecondsSinceEpoch - start;

    dev.log(
      '!! [${err.response?.statusCode}] ($ms ms) '
      '${err.type} ${req.method} ${req.uri}',
      name: 'network',
      error: err.message,
      stackTrace: err.stackTrace,
    );

    if (err.response?.data != null) {
      dev.log(
        'error-data: ${_truncate(_sanitize(err.response?.data))}',
        name: 'network',
      );
    }

    handler.next(err);
  }

  Object? _sanitize(Object? data) {
    if (data == null) return null;

    if (data is Map) {
      return data.map((k, v) {
        final key = k.toString().toLowerCase();
        return MapEntry(k, _sensitiveKeys.contains(key) ? '***' : v);
      });
    }

    if (data is List) {
      return data.map(_sanitize).toList();
    }

    return data;
  }

  String _truncate(Object? value) {
    final s = value?.toString() ?? '';
    if (s.length <= maxBodyChars) return s;
    return '${s.substring(0, maxBodyChars)}...(truncated)';
  }
}
