// dart format off
// coverage:ignore-file
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Small title shown above the login message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginHeaderTitle;

  /// Main message on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginHeaderSubtitle;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get loginForgotPassword;

  /// Primary login button text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignInCta;

  /// Text under the login button
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get loginCreateNewAccount;

  /// Separator text above social login buttons
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get loginOrContinueWith;

  /// Tooltip to show password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// Tooltip to hide password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// Validation error when email is empty
  ///
  /// In en, this message translates to:
  /// **'Write your email'**
  String get validationEmailEmpty;

  /// Validation error when email is invalid
  ///
  /// In en, this message translates to:
  /// **'The email is not valid'**
  String get validationEmailInvalid;

  /// Validation error when password is empty
  ///
  /// In en, this message translates to:
  /// **'Write your password'**
  String get validationPasswordEmpty;

  /// Validation error when password is too short
  ///
  /// In en, this message translates to:
  /// **'Must be at least {min} characters'**
  String validationPasswordMin(int min);

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to get started'**
  String get registerSubtitle;

  /// No description provided for @registerFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get registerFirstNameLabel;

  /// No description provided for @registerLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get registerLastNameLabel;

  /// No description provided for @registerUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get registerUsernameLabel;

  /// No description provided for @registerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmailLabel;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordLabel;

  /// No description provided for @registerPasswordAgainLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat Password'**
  String get registerPasswordAgainLabel;

  /// No description provided for @registerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get registerPhoneLabel;

  /// No description provided for @registerSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get registerSubmitCta;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @validationFieldEmpty.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty'**
  String get validationFieldEmpty;

  /// No description provided for @validationPasswordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 12 characters, with one uppercase, one lowercase and one special character'**
  String get validationPasswordComplexity;

  /// No description provided for @validationPasswordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsNotMatch;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We have sent you a verification link. Please check your inbox (and spam).'**
  String get verifyEmailSubtitle;

  /// No description provided for @verifyEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String verifyEmailLabel(String email);

  /// No description provided for @verifyEmailResendCta.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyEmailResendCta;

  /// No description provided for @verifyEmailConfirmedCta.
  ///
  /// In en, this message translates to:
  /// **'I have already verified it'**
  String get verifyEmailConfirmedCta;

  /// No description provided for @verifyEmailGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go to login'**
  String get verifyEmailGoBack;

  /// No description provided for @verifyEmailLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get verifyEmailLogout;

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor verification'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your authenticator app or a recovery code.'**
  String get twoFactorSubtitle;

  /// No description provided for @twoFactorAppCodeTab.
  ///
  /// In en, this message translates to:
  /// **'App code'**
  String get twoFactorAppCodeTab;

  /// No description provided for @twoFactorRecoveryCodeTab.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get twoFactorRecoveryCodeTab;

  /// No description provided for @twoFactorAppCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get twoFactorAppCodeLabel;

  /// No description provided for @twoFactorRecoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get twoFactorRecoveryCodeLabel;

  /// No description provided for @twoFactorSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get twoFactorSubmitCta;

  /// No description provided for @twoFactorBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get twoFactorBackToLogin;

  /// Text shown in the AppBar of the Counter Page
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counterAppBarTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get tabDocuments;

  /// No description provided for @tabCheckins.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get tabCheckins;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @checkinTitle.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get checkinTitle;

  /// No description provided for @checkinEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get checkinEmpty;

  /// No description provided for @checkinNoPatient.
  ///
  /// In en, this message translates to:
  /// **'No patient'**
  String get checkinNoPatient;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @checkinEntry.
  ///
  /// In en, this message translates to:
  /// **'Check-in: {value}'**
  String checkinEntry(String value);

  /// No description provided for @checkinExit.
  ///
  /// In en, this message translates to:
  /// **'Check-out: {value}'**
  String checkinExit(String value);

  /// No description provided for @recoverPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover password'**
  String get recoverPasswordTitle;

  /// No description provided for @recoverPasswordGetCodeMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a recovery link'**
  String get recoverPasswordGetCodeMsg;

  /// No description provided for @recoverPasswordGetCodeCta.
  ///
  /// In en, this message translates to:
  /// **'Request recovery'**
  String get recoverPasswordGetCodeCta;

  /// No description provided for @recoverPasswordCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get recoverPasswordCodeLabel;

  /// No description provided for @recoverPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get recoverPasswordNewLabel;

  /// No description provided for @recoverPasswordRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get recoverPasswordRepeatLabel;

  /// No description provided for @recoverPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get recoverPasswordSubmit;

  /// No description provided for @recoverPasswordCodeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get recoverPasswordCodeEmpty;

  /// No description provided for @recoverPasswordMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get recoverPasswordMatchError;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get documentsEmpty;

  /// No description provided for @documentsDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get documentsDownload;

  /// No description provided for @documentsSign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get documentsSign;

  /// No description provided for @documentsSigned.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get documentsSigned;

  /// No description provided for @documentsNotSigned.
  ///
  /// In en, this message translates to:
  /// **'Awaiting signature'**
  String get documentsNotSigned;

  /// No description provided for @documentsSignTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign document'**
  String get documentsSignTitle;

  /// No description provided for @documentsSignDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature below'**
  String get documentsSignDescription;

  /// No description provided for @documentsSignClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get documentsSignClear;

  /// No description provided for @documentsSignSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit signature'**
  String get documentsSignSubmit;

  /// No description provided for @passwordRequirementLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 12 characters'**
  String get passwordRequirementLength;

  /// No description provided for @passwordRequirementLowercase.
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter'**
  String get passwordRequirementLowercase;

  /// No description provided for @passwordRequirementUppercase.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get passwordRequirementUppercase;

  /// No description provided for @passwordRequirementSpecial.
  ///
  /// In en, this message translates to:
  /// **'One special character'**
  String get passwordRequirementSpecial;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get passwordStrengthStrong;

  /// No description provided for @profileAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get profileAccountInfo;

  /// No description provided for @profileEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String profileEmployeeId(String id);

  /// No description provided for @profileSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profileSectionPersonal;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSectionSecurity;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// No description provided for @profileLabelFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get profileLabelFirstName;

  /// No description provided for @profileLabelLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get profileLabelLastName;

  /// No description provided for @profileLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileLabelEmail;

  /// No description provided for @profileLabel2FA.
  ///
  /// In en, this message translates to:
  /// **'2FA'**
  String get profileLabel2FA;

  /// No description provided for @profileLabelStatus.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get profileLabelStatus;

  /// No description provided for @profileLabelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get profileLabelPassword;

  /// No description provided for @profileLabelCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get profileLabelCreated;

  /// No description provided for @profileLabelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLabelLanguage;

  /// No description provided for @profileLabelTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileLabelTheme;

  /// No description provided for @profileValueVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileValueVerified;

  /// No description provided for @profileValuePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get profileValuePending;

  /// No description provided for @profileValueEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get profileValueEnabled;

  /// No description provided for @profileValueDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get profileValueDisabled;

  /// No description provided for @profileValueActivated.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get profileValueActivated;

  /// No description provided for @profileValueDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get profileValueDeactivated;

  /// No description provided for @profileActionChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileActionChangePassword;

  /// No description provided for @profileLogoutCta.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogoutCta;

  /// No description provided for @profilePhotoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profilePhotoSheetTitle;

  /// No description provided for @profilePhotoSheetCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profilePhotoSheetCamera;

  /// No description provided for @profilePhotoSheetGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profilePhotoSheetGallery;

  /// No description provided for @themeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSheetTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSheetTitle;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @updateProfileCta.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get updateProfileCta;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get changePasswordMatchError;

  /// No description provided for @changePasswordSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordSubmitCta;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcome;

  /// No description provided for @homeWelcomeNamed.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String homeWelcomeNamed(String name);

  /// No description provided for @homeBuildFun.
  ///
  /// In en, this message translates to:
  /// **'Let\'s build something fun!'**
  String get homeBuildFun;

  /// No description provided for @homeTabTitle.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get homeTabTitle;

  /// No description provided for @homeCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright Â© {year}. TCG Platform Mobile. All rights reserved.'**
  String homeCopyright(int year);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
