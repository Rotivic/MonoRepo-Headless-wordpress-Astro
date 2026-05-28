import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';

class LoginResult {
  final String? token;
  final User? user;
  final bool twoFactorRequired;
  final String? challengeToken;

  LoginResult({
    this.token,
    this.user,
    this.twoFactorRequired = false,
    this.challengeToken,
  });
}
