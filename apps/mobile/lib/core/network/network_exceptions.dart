import 'package:dio/dio.dart';

class NetworkException implements Exception {
  NetworkException(this.message, {this.code});

  factory NetworkException.fromDioException(DioException error) {
    String message = _mapDioExceptionToMessage(error);
    String? code;

    if (error.type == DioExceptionType.badResponse &&
        error.response?.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;

      // Intentar extraer mensaje específico del backend si existe
      if (data.containsKey('message')) {
        message = data['message'].toString();
      }

      // Intentar extraer código de error específico del backend si existe
      if (data.containsKey('code')) {
        code = data['code'].toString();
      }
    }

    return NetworkException(message, code: code);
  }

  final String message;
  final String? code;
}

String _mapDioExceptionToMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Tiempo de conexión agotado';

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? -1;
      if (statusCode == 401) return 'No autorizado';
      if (statusCode == 403) return 'Acceso denegado';
      if (statusCode == 404) return 'No encontrado';
      return 'Error del servidor ($statusCode)';

    case DioExceptionType.cancel:
      return 'Solicitud cancelada';

    case DioExceptionType.badCertificate:
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return 'Error de red desconocido';
  }
}
