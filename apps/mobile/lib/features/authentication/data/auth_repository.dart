import 'package:dio/dio.dart';
import 'package:tcg_platform_mobile/core/network/api_client.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/features/authentication/data/dtos/user_dto.dart';
import 'package:tcg_platform_mobile/features/authentication/data/mappers/user_mapper.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/login_result.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository(this.apiClient);

  Future<User> getUserByToken(String token) async {
    try {
      final meDto = await apiClient.getCurrentUser('Bearer $token');
      final userDto = UserDto.fromJson(meDto.data);
      return userDto.toDomain();
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.login({
        'email': email,
        'password': password,
        'device_name': 'android',
      });

      if (response.twoFactor == true) {
        return LoginResult(
          twoFactorRequired: true,
          challengeToken: response.challengeToken,
        );
      }

      final token = response.token!;
      final meDto = await apiClient.getCurrentUser('Bearer $token');
      final userDto = UserDto.fromJson(meDto.data);

      return LoginResult(
        token: token,
        user: userDto.toDomain(),
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  Future<LoginResult> verifyTwoFactor({
    required String challengeToken,
    String? code,
    String? recoveryCode,
  }) async {
    try {
      final body = {
        'challenge_token': challengeToken,
        'device_name': 'android',
      };

      if (code != null) body['code'] = code;
      if (recoveryCode != null) body['recovery_code'] = recoveryCode;

      final response = await apiClient.twoFactorLogin(body);

      final token = response.token!;
      final meDto = await apiClient.getCurrentUser('Bearer $token');
      final userDto = UserDto.fromJson(meDto.data);

      return LoginResult(
        token: token,
        user: userDto.toDomain(),
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  Future<String> sendVerificationEmail(String token) async {
    try {
      await apiClient.sendVerification('Bearer $token');
      return 'Correo de verificaciÃ³n reenviado';
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> verifyEmailCode({
    required String token,
    required String code,
  }) async {
    try {
      await apiClient.verifyEmailCode(
        'Bearer $token',
        {'code': code},
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.forgotPassword({'email': email});
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  Future<LoginResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await apiClient.register({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': 'android',
      });

      final tokenDto = await apiClient.login({
        'email': email,
        'password': password,
        'device_name': 'android',
      });

      final token = tokenDto.token!;
      final meDto = await apiClient.getCurrentUser('Bearer $token');
      final userDto = UserDto.fromJson(meDto.data);

      return LoginResult(
        token: token,
        user: userDto.toDomain(),
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> logout(String token) async {
    try {
      await apiClient.logout('Bearer $token');
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }
}
