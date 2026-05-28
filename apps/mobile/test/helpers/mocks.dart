import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcg_platform_mobile/features/authentication/data/auth_repository.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/login_result.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeLoginResult extends Fake implements LoginResult {}

class FakeUser extends Fake implements User {}

/// Helper para crear un User mÃ­nimo
User makeUser() {
  return User(
    id: 1,
    email: 'a@a.com',
    firstName: 'Test',
    lastName: 'User',
    enabled: true,
    isVerified: true,
  );
}

LoginResult makeLoginResult({String token = 'abc'}) {
  return LoginResult(
    token: token,
    user: makeUser(),
  );
}
