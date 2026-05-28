class NetworkConstants {
  static const baseUrlDev = String.fromEnvironment(
    'TCG_API_URL',
    defaultValue: 'http://10.0.2.2:8080/wp-json',
  );
  static const baseUrlProd = String.fromEnvironment(
    'TCG_API_URL_PROD',
    defaultValue: 'https://example.com/wp-json',
  );

  // WordPress REST API endpoints.
  static const callWpRoot = '/';
  static const callWpPosts = '/wp/v2/posts';
  static const callWpPages = '/wp/v2/pages';

  // TCG Platform API endpoints.
  static const callTcgHealth = '/tcg/v1/health';
  static const callLogin = '/tcg/v1/login';
  static const callCurrentUser = '/tcg/v1/me';
  static const callRegister = '/tcg/v1/register';
  static const callLogout = '/tcg/v1/logout';

  // Pending TCG Platform API endpoints.
  static const callTwoFactorLogin = '/tcg/v1/two-factor/login';
  static const callSendVerification = '/email/verification-notification';
  static const callVerifyEmailCode = '/email/verify';
  static const callForgotPassword = '/forgot-password';

  // Legacy / shared.
  static const callUpdateUser = '/users/{id}';
  static const callRecover = 'external/changePassword';
  static const callReset = 'user/updatePassword';

  // Legacy mobile profile endpoints.
  static const callProfileUpdate = '/profile';
  static const callProfileAvatar = '/profile/avatar';
  static const callProfilePassword = '/profile/password';

  static const callListCheckinPaginated = 'checkin/getEmployeeCheckinsApp';
  static const callUpdateUserImage = 'user/updateUserImage';
  static const callUserData = 'user/data';
  static const callGroupDropdown = 'group/dropdown';
  static const callUserDropdown = 'user/dropdownUser';
  static const callGetAllDocumentsPaginated =
      'documentation/getAllDocumentsByEmployee';
  static const callSignDocument = 'documentation/signDocument';
}
