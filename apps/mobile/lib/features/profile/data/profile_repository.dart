import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tcg_platform_mobile/core/network/api_client.dart';
import 'package:tcg_platform_mobile/core/network/network_exceptions.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/profile/data/dtos/change_password_request_dto.dart';
import 'package:tcg_platform_mobile/features/profile/data/dtos/user_profile_dto.dart';
import 'package:tcg_platform_mobile/features/profile/data/mappers/update_user_mapper.dart';
import 'package:tcg_platform_mobile/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:tcg_platform_mobile/features/profile/domain/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this.apiClient, this.sessionStore);

  final ApiClient apiClient;
  final SessionStore sessionStore;

  Future<UserProfile> getUserProfile() async {
    try {
      final token = sessionStore.token;
      if (token == null) throw NetworkException('No hay sesiÃ³n activa');

      final response = await apiClient.getCurrentUser('Bearer $token');
      final userDto = UserProfileDto.fromJson(response.data);

      return userDto.toDomain();
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<String> updateUserProfile(UserProfile profile) async {
    try {
      final token = sessionStore.token;
      if (token == null) throw NetworkException('No hay sesiÃ³n activa');

      final response = await apiClient.updateProfileInformation(
        'Bearer $token',
        profile.toUpdateRequest().toJson(),
      );

      return response.message ?? 'Perfil actualizado correctamente';
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<String> updateAvatar(File avatarFile) async {
    try {
      final token = sessionStore.token;
      if (token == null) throw NetworkException('No hay sesiÃ³n activa');

      final avatarPart = await MultipartFile.fromFile(
        avatarFile.path,
        filename: avatarFile.uri.pathSegments.last,
      );

      final response = await apiClient.updateProfileAvatar(
        'Bearer $token',
        avatarPart,
      );

      return response.message ?? 'Avatar actualizado correctamente';
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = sessionStore.token;
      if (token == null) throw NetworkException('No hay sesiÃ³n activa');

      final request = ChangePasswordRequestDto(
        currentPassword: oldPassword,
        password: newPassword,
        passwordConfirmation: newPassword,
      );

      final response = await apiClient.updateProfilePassword(
        'Bearer $token',
        request.toJson(),
      );

      return response.message ?? 'ContraseÃ±a actualizada correctamente';
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }
}
