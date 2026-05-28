import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tcg_platform_mobile/core/session_store/session_store.dart';

class AppSettingsState {
  const AppSettingsState({
    required this.themeMode,
    required this.locale,
  });

  final ThemeMode themeMode;
  final Locale? locale;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._sessionStore)
    : super(
        AppSettingsState(
          themeMode: _sessionStore.themeMode,
          locale: _sessionStore.localeCode != null
              ? Locale(_sessionStore.localeCode!)
              : null,
        ),
      );

  final SessionStore _sessionStore;

  void setThemeMode(ThemeMode mode) {
    _sessionStore.saveThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  /// locale == null => seguir sistema
  void setLocale(Locale? locale) {
    _sessionStore.saveLocale(locale?.languageCode);
    if (locale == null) {
      emit(state.copyWith(clearLocale: true));
    } else {
      emit(state.copyWith(locale: locale, clearLocale: false));
    }
  }
}
