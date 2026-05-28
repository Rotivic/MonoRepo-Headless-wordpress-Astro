// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginHeaderTitle => 'Bienvenido/a';

  @override
  String get loginHeaderSubtitle => 'Inicia sesiÃ³n para continuar';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'ContraseÃ±a';

  @override
  String get loginForgotPassword => 'Â¿Olvidaste tu contraseÃ±a?';

  @override
  String get loginSignInCta => 'Entrar';

  @override
  String get loginCreateNewAccount => 'Crear nueva cuenta';

  @override
  String get loginOrContinueWith => 'O continÃºa con';

  @override
  String get loginShowPassword => 'Mostrar contraseÃ±a';

  @override
  String get loginHidePassword => 'Ocultar contraseÃ±a';

  @override
  String get validationEmailEmpty => 'Escribe tu email';

  @override
  String get validationEmailInvalid => 'El email no es vÃ¡lido';

  @override
  String get validationPasswordEmpty => 'Escribe tu contraseÃ±a';

  @override
  String validationPasswordMin(int min) {
    return 'Debe tener al menos $min caracteres';
  }

  @override
  String get registerTitle => 'Registro';

  @override
  String get registerSubtitle => 'Crea una cuenta para empezar';

  @override
  String get registerFirstNameLabel => 'Nombre';

  @override
  String get registerLastNameLabel => 'Apellidos';

  @override
  String get registerUsernameLabel => 'Nombre de usuario';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerPasswordLabel => 'ContraseÃ±a';

  @override
  String get registerPasswordAgainLabel => 'Repetir contraseÃ±a';

  @override
  String get registerPhoneLabel => 'TelÃ©fono';

  @override
  String get registerSubmitCta => 'Registrarse';

  @override
  String get registerAlreadyHaveAccount => 'Â¿Ya tienes una cuenta? Inicia sesiÃ³n';

  @override
  String get validationFieldEmpty => 'Este campo no puede estar vacÃ­o';

  @override
  String get validationPasswordComplexity => 'La contraseÃ±a debe tener al menos 12 caracteres, una mayÃºscula, una minÃºscula y un carÃ¡cter especial';

  @override
  String get validationPasswordsNotMatch => 'Las contraseÃ±as no coinciden';

  @override
  String get verifyEmailTitle => 'Verifica tu email';

  @override
  String get verifyEmailSubtitle => 'Te hemos enviado un enlace de verificaciÃ³n. Revisa tu bandeja de entrada (y spam).';

  @override
  String verifyEmailLabel(String email) {
    return 'Email: $email';
  }

  @override
  String get verifyEmailResendCta => 'Reenviar email';

  @override
  String get verifyEmailConfirmedCta => 'Ya lo he verificado';

  @override
  String get verifyEmailGoBack => 'Ir al login';

  @override
  String get verifyEmailLogout => 'Salir';

  @override
  String get twoFactorTitle => 'VerificaciÃ³n en dos pasos';

  @override
  String get twoFactorSubtitle => 'Introduce el cÃ³digo de tu app autenticadora o un cÃ³digo de recuperaciÃ³n.';

  @override
  String get twoFactorAppCodeTab => 'CÃ³digo app';

  @override
  String get twoFactorRecoveryCodeTab => 'CÃ³digo recuperaciÃ³n';

  @override
  String get twoFactorAppCodeLabel => 'CÃ³digo de 6 dÃ­gitos';

  @override
  String get twoFactorRecoveryCodeLabel => 'CÃ³digo de recuperaciÃ³n';

  @override
  String get twoFactorSubmitCta => 'Continuar';

  @override
  String get twoFactorBackToLogin => 'Volver al login';

  @override
  String get counterAppBarTitle => 'Contador';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabDocuments => 'Documentos';

  @override
  String get tabCheckins => 'Jornadas';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get checkinTitle => 'Jornadas';

  @override
  String get checkinEmpty => 'No hay registros';

  @override
  String get checkinNoPatient => 'Sin paciente';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonBack => 'Volver';

  @override
  String checkinEntry(String value) {
    return 'Entrada: $value';
  }

  @override
  String checkinExit(String value) {
    return 'Salida: $value';
  }

  @override
  String get recoverPasswordTitle => 'Recuperar contraseÃ±a';

  @override
  String get recoverPasswordGetCodeMsg => 'Introduce tu email para recibir un enlace de recuperaciÃ³n';

  @override
  String get recoverPasswordGetCodeCta => 'Solicitar recuperaciÃ³n';

  @override
  String get recoverPasswordCodeLabel => 'CÃ³digo de verificaciÃ³n';

  @override
  String get recoverPasswordNewLabel => 'Nueva contraseÃ±a';

  @override
  String get recoverPasswordRepeatLabel => 'Repetir contraseÃ±a';

  @override
  String get recoverPasswordSubmit => 'Restablecer contraseÃ±a';

  @override
  String get recoverPasswordCodeEmpty => 'Introduce el cÃ³digo';

  @override
  String get recoverPasswordMatchError => 'Las contraseÃ±as no coinciden';

  @override
  String get documentsTitle => 'Documentos';

  @override
  String get documentsEmpty => 'No hay documentos';

  @override
  String get documentsDownload => 'Descargar';

  @override
  String get documentsSign => 'Firmar';

  @override
  String get documentsSigned => 'Firmado';

  @override
  String get documentsNotSigned => 'Pendiente de firma';

  @override
  String get documentsSignTitle => 'Firmar documento';

  @override
  String get documentsSignDescription => 'Dibuja tu firma a continuaciÃ³n';

  @override
  String get documentsSignClear => 'Limpiar';

  @override
  String get documentsSignSubmit => 'Enviar firma';

  @override
  String get passwordRequirementLength => 'MÃ­nimo 12 caracteres';

  @override
  String get passwordRequirementLowercase => 'Una minÃºscula';

  @override
  String get passwordRequirementUppercase => 'Una mayÃºscula';

  @override
  String get passwordRequirementSpecial => 'Un carÃ¡cter especial';

  @override
  String get passwordStrengthWeak => 'DÃ©bil';

  @override
  String get passwordStrengthMedium => 'Media';

  @override
  String get passwordStrengthGood => 'Buena';

  @override
  String get passwordStrengthStrong => 'Segura';

  @override
  String get profileAccountInfo => 'InformaciÃ³n de la cuenta';

  @override
  String profileEmployeeId(String id) {
    return 'ID: $id';
  }

  @override
  String get profileSectionPersonal => 'InformaciÃ³n personal';

  @override
  String get profileSectionSecurity => 'Seguridad';

  @override
  String get profileSectionAccount => 'Cuenta';

  @override
  String get profileSectionPreferences => 'Preferencias';

  @override
  String get profileLabelFirstName => 'Nombre';

  @override
  String get profileLabelLastName => 'Apellidos';

  @override
  String get profileLabelEmail => 'Email';

  @override
  String get profileLabel2FA => '2FA';

  @override
  String get profileLabelStatus => 'Estado cuenta';

  @override
  String get profileLabelPassword => 'ContraseÃ±a';

  @override
  String get profileLabelCreated => 'Creado';

  @override
  String get profileLabelLanguage => 'Idioma';

  @override
  String get profileLabelTheme => 'Tema';

  @override
  String get profileValueVerified => 'Verificado';

  @override
  String get profileValuePending => 'Pendiente';

  @override
  String get profileValueEnabled => 'Habilitada';

  @override
  String get profileValueDisabled => 'Deshabilitada';

  @override
  String get profileValueActivated => 'Activado';

  @override
  String get profileValueDeactivated => 'Desactivado';

  @override
  String get profileActionChangePassword => 'Cambiar contraseÃ±a';

  @override
  String get profileLogoutCta => 'Cerrar sesiÃ³n';

  @override
  String get profilePhotoSheetTitle => 'Cambiar foto de perfil';

  @override
  String get profilePhotoSheetCamera => 'Hacer foto';

  @override
  String get profilePhotoSheetGallery => 'Elegir de la galerÃ­a';

  @override
  String get themeSheetTitle => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageSheetTitle => 'Idioma';

  @override
  String get languageSpanish => 'EspaÃ±ol';

  @override
  String get languageEnglish => 'English';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get updateProfileCta => 'Actualizar perfil';

  @override
  String get changePasswordTitle => 'Cambiar contraseÃ±a';

  @override
  String get changePasswordCurrentLabel => 'ContraseÃ±a actual';

  @override
  String get changePasswordNewLabel => 'Nueva contraseÃ±a';

  @override
  String get changePasswordConfirmLabel => 'Confirmar nueva contraseÃ±a';

  @override
  String get changePasswordMatchError => 'Las contraseÃ±as no coinciden';

  @override
  String get changePasswordSubmitCta => 'Actualizar contraseÃ±a';

  @override
  String get homeWelcome => 'Bienvenido';

  @override
  String homeWelcomeNamed(String name) {
    return 'Bienvenido, $name';
  }

  @override
  String get homeBuildFun => 'Â¡Construyamos algo divertido!';

  @override
  String get homeTabTitle => 'INICIO';

  @override
  String homeCopyright(int year) {
    return 'Copyright Â© $year. TCG Platform Mobile. Todos los derechos reservados.';
  }
}
