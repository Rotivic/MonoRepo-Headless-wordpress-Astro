// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginHeaderTitle => 'Welcome';

  @override
  String get loginHeaderSubtitle => 'Sign in to continue';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginSignInCta => 'Sign in';

  @override
  String get loginCreateNewAccount => 'Create new account';

  @override
  String get loginOrContinueWith => 'Or continue with';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get validationEmailEmpty => 'Write your email';

  @override
  String get validationEmailInvalid => 'The email is not valid';

  @override
  String get validationPasswordEmpty => 'Write your password';

  @override
  String validationPasswordMin(int min) {
    return 'Must be at least $min characters';
  }

  @override
  String get registerTitle => 'Register';

  @override
  String get registerSubtitle => 'Create an account to get started';

  @override
  String get registerFirstNameLabel => 'First Name';

  @override
  String get registerLastNameLabel => 'Last Name';

  @override
  String get registerUsernameLabel => 'Username';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerPasswordAgainLabel => 'Repeat Password';

  @override
  String get registerPhoneLabel => 'Phone';

  @override
  String get registerSubmitCta => 'Sign Up';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get validationFieldEmpty => 'This field cannot be empty';

  @override
  String get validationPasswordComplexity => 'Password must be at least 12 characters, with one uppercase, one lowercase and one special character';

  @override
  String get validationPasswordsNotMatch => 'Passwords do not match';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailSubtitle => 'We have sent you a verification link. Please check your inbox (and spam).';

  @override
  String verifyEmailLabel(String email) {
    return 'Email: $email';
  }

  @override
  String get verifyEmailResendCta => 'Resend email';

  @override
  String get verifyEmailConfirmedCta => 'I have already verified it';

  @override
  String get verifyEmailGoBack => 'Go to login';

  @override
  String get verifyEmailLogout => 'Logout';

  @override
  String get twoFactorTitle => 'Two-factor verification';

  @override
  String get twoFactorSubtitle => 'Enter the code from your authenticator app or a recovery code.';

  @override
  String get twoFactorAppCodeTab => 'App code';

  @override
  String get twoFactorRecoveryCodeTab => 'Recovery code';

  @override
  String get twoFactorAppCodeLabel => '6-digit code';

  @override
  String get twoFactorRecoveryCodeLabel => 'Recovery code';

  @override
  String get twoFactorSubmitCta => 'Continue';

  @override
  String get twoFactorBackToLogin => 'Back to login';

  @override
  String get counterAppBarTitle => 'Counter';

  @override
  String get tabHome => 'Home';

  @override
  String get tabDocuments => 'Documents';

  @override
  String get tabCheckins => 'Shifts';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabProfile => 'Profile';

  @override
  String get checkinTitle => 'Shifts';

  @override
  String get checkinEmpty => 'No records';

  @override
  String get checkinNoPatient => 'No patient';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String checkinEntry(String value) {
    return 'Check-in: $value';
  }

  @override
  String checkinExit(String value) {
    return 'Check-out: $value';
  }

  @override
  String get recoverPasswordTitle => 'Recover password';

  @override
  String get recoverPasswordGetCodeMsg => 'Enter your email to receive a recovery link';

  @override
  String get recoverPasswordGetCodeCta => 'Request recovery';

  @override
  String get recoverPasswordCodeLabel => 'Verification code';

  @override
  String get recoverPasswordNewLabel => 'New password';

  @override
  String get recoverPasswordRepeatLabel => 'Repeat password';

  @override
  String get recoverPasswordSubmit => 'Reset password';

  @override
  String get recoverPasswordCodeEmpty => 'Enter the code';

  @override
  String get recoverPasswordMatchError => 'Passwords do not match';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsEmpty => 'No documents';

  @override
  String get documentsDownload => 'Download';

  @override
  String get documentsSign => 'Sign';

  @override
  String get documentsSigned => 'Signed';

  @override
  String get documentsNotSigned => 'Awaiting signature';

  @override
  String get documentsSignTitle => 'Sign document';

  @override
  String get documentsSignDescription => 'Draw your signature below';

  @override
  String get documentsSignClear => 'Clear';

  @override
  String get documentsSignSubmit => 'Submit signature';

  @override
  String get passwordRequirementLength => 'Minimum 12 characters';

  @override
  String get passwordRequirementLowercase => 'One lowercase letter';

  @override
  String get passwordRequirementUppercase => 'One uppercase letter';

  @override
  String get passwordRequirementSpecial => 'One special character';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Secure';

  @override
  String get profileAccountInfo => 'Account information';

  @override
  String profileEmployeeId(String id) {
    return 'ID: $id';
  }

  @override
  String get profileSectionPersonal => 'Personal information';

  @override
  String get profileSectionSecurity => 'Security';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileLabelFirstName => 'First Name';

  @override
  String get profileLabelLastName => 'Last Name';

  @override
  String get profileLabelEmail => 'Email';

  @override
  String get profileLabel2FA => '2FA';

  @override
  String get profileLabelStatus => 'Account status';

  @override
  String get profileLabelPassword => 'Password';

  @override
  String get profileLabelCreated => 'Created';

  @override
  String get profileLabelLanguage => 'Language';

  @override
  String get profileLabelTheme => 'Theme';

  @override
  String get profileValueVerified => 'Verified';

  @override
  String get profileValuePending => 'Pending';

  @override
  String get profileValueEnabled => 'Enabled';

  @override
  String get profileValueDisabled => 'Disabled';

  @override
  String get profileValueActivated => 'Activated';

  @override
  String get profileValueDeactivated => 'Deactivated';

  @override
  String get profileActionChangePassword => 'Change password';

  @override
  String get profileLogoutCta => 'Logout';

  @override
  String get profilePhotoSheetTitle => 'Change profile photo';

  @override
  String get profilePhotoSheetCamera => 'Take photo';

  @override
  String get profilePhotoSheetGallery => 'Choose from gallery';

  @override
  String get themeSheetTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSheetTitle => 'Language';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get updateProfileCta => 'Update profile';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordMatchError => 'Passwords do not match';

  @override
  String get changePasswordSubmitCta => 'Update password';

  @override
  String get homeWelcome => 'Welcome';

  @override
  String homeWelcomeNamed(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeBuildFun => 'Let\'s build something fun!';

  @override
  String get homeTabTitle => 'HOME';

  @override
  String homeCopyright(int year) {
    return 'Copyright Â© $year. TCG Platform Mobile. All rights reserved.';
  }
}
