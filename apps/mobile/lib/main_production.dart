import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tcg_platform_mobile/app/app.dart';
import 'package:tcg_platform_mobile/bootstrap.dart';
import 'package:tcg_platform_mobile/core/network/api_client.dart';
import 'package:tcg_platform_mobile/core/network/constants.dart';
import 'package:tcg_platform_mobile/core/network/dio_provider.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const baseUrl = NetworkConstants.baseUrlProd;

  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final session = SessionStore(storage);
  await session.initialize();

  final dio = DioProvider.create(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
    tokenProvider: () async => session.token,
  );

  final apiClient = ApiClient(dio);
  final authRepository = AuthRepository(apiClient);

  await bootstrap(
    () => App(
      authRepository: authRepository,
      apiClient: apiClient,
      sessionStore: session,
    ),
  );
}
