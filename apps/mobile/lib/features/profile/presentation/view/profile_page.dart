import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tcg_platform_mobile/app/routes.dart';
import 'package:tcg_platform_mobile/core/app_settings/app_settings_cubit.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:tcg_platform_mobile/features/profile/data/profile_repository.dart';
import 'package:tcg_platform_mobile/features/profile/domain/models/user_profile.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/change_password_page.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/edit_profile_page.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/widgets/profile_divider.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/widgets/profile_header.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/widgets/profile_logout_tile.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/widgets/profile_row.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/widgets/profile_section_card.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        profileRepository: context.read<ProfileRepository>(),
      )..getUserProfile(),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _openEditProfile(BuildContext context, UserProfile user) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(user: user),
      ),
    );

    if (updated == true && context.mounted) {
      context.read<ProfileCubit>().refresh();
    }
  }

  Future<File?> _showImageSourceSheet(BuildContext context) async {
    final picker = ImagePicker();
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.spacing.x8),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.x12,
              0,
              theme.spacing.x12,
              theme.spacing.x8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetTitle(l10n.profilePhotoSheetTitle),
                _SheetOptionTile(
                  selected: false,
                  title: l10n.profilePhotoSheetCamera,
                  icon: Icons.camera_alt_outlined,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                _SheetOptionTile(
                  selected: false,
                  title: l10n.profilePhotoSheetGallery,
                  icon: Icons.photo_library_outlined,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                SizedBox(height: theme.spacing.x10),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return null;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    return picked != null ? File(picked.path) : null;
  }

  Future<void> _changePhoto(BuildContext context) async {
    final file = await _showImageSourceSheet(context);
    if (file == null || !context.mounted) return;
    await context.read<ProfileCubit>().updateAvatar(file);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final l10n = context.l10n;

    return AuthBackground(
      child: SafeArea(
        child: BlocListener<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading)
                return const Center(child: CircularProgressIndicator());
              final user = (state is ProfileLoaded) ? state.user : null;
              if (user == null) return const SizedBox.shrink();

              return BlocBuilder<AppSettingsCubit, AppSettingsState>(
                builder: (context, settings) {
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.x32,
                      vertical: spacing.x24,
                    ),
                    children: [
                      ProfileHeader(
                        title: l10n.tabProfile,
                        name: user.fullName,
                        subtitle: user.email,
                        role: user.isEnabled
                            ? l10n.profileValueEnabled
                            : l10n.profileValueDisabled,
                        employeeId: user.id.toString(),
                        imageUrl: user.avatarUrl,
                        backendBaseUrl: 'http://192.168.1.15:8000',
                        onEditPressed: () => _openEditProfile(context, user),
                        onChangePhotoPressed: () => _changePhoto(context),
                      ),
                      SizedBox(height: spacing.sectionGap),
                      ProfileSectionCard(
                        title: l10n.profileSectionPersonal,
                        children: [
                          ProfileRow.readOnly(
                            icon: Icons.person_outline_rounded,
                            title: l10n.profileLabelFirstName,
                            value: user.firstName,
                          ),
                          const ProfileDivider(),
                          ProfileRow.readOnly(
                            icon: Icons.person_outline_rounded,
                            title: l10n.profileLabelLastName,
                            value: user.lastName,
                          ),
                          const ProfileDivider(),
                          ProfileRow.readOnly(
                            icon: Icons.mail_outline_rounded,
                            title: l10n.profileLabelEmail,
                            value: user.email,
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.x16),
                      ProfileSectionCard(
                        title: l10n.profileSectionSecurity,
                        children: [
                          ProfileRow.readOnly(
                            icon: Icons.verified_user_outlined,
                            title: l10n.profileLabelEmail,
                            value: user.isVerified
                                ? l10n.profileValueVerified
                                : l10n.profileValuePending,
                          ),
                          const ProfileDivider(),
                          ProfileRow.readOnly(
                            icon: Icons.security_outlined,
                            title: l10n.profileLabel2FA,
                            value: user.twoFactorEnabled
                                ? l10n.profileValueActivated
                                : l10n.profileValueDeactivated,
                          ),
                          const ProfileDivider(),
                          ProfileRow.action(
                            icon: Icons.lock_reset_rounded,
                            title: l10n.profileLabelPassword,
                            value: l10n.profileActionChangePassword,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ChangePasswordPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.x16),
                      ProfileSectionCard(
                        title: l10n.profileSectionPreferences,
                        children: [
                          ProfileRow.action(
                            icon: Icons.language_rounded,
                            title: l10n.profileLabelLanguage,
                            value: _localeLabel(l10n, settings.locale),
                            onTap: () => _showLanguageSheet(context),
                          ),
                          const ProfileDivider(),
                          ProfileRow.action(
                            icon: Icons.dark_mode_outlined,
                            title: l10n.profileLabelTheme,
                            value: _themeLabel(l10n, settings.themeMode),
                            onTap: () => _showThemeSheet(context),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sectionGap),
                      ProfileLogoutTile(
                        color: theme.colorScheme.error,
                        onLogout: () async {
                          await context.read<AuthCubit>().logout();
                          if (!context.mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (_) => false,
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
  }

  static String _localeLabel(AppLocalizations l10n, Locale? locale) {
    if (locale == null) return l10n.themeSystem;
    if (locale.languageCode == 'es') return l10n.languageSpanish;
    if (locale.languageCode == 'en') return l10n.languageEnglish;
    return locale.toLanguageTag();
  }

  static Future<void> _showThemeSheet(BuildContext context) async {
    final cubit = context.read<AppSettingsCubit>();
    final theme = Theme.of(context);
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.spacing.x8),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
            bloc: cubit,
            builder: (context, settings) {
              final current = settings.themeMode;
              void select(ThemeMode mode) {
                cubit.setThemeMode(mode);
                Navigator.of(context).pop();
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.spacing.x12,
                  0,
                  theme.spacing.x12,
                  theme.spacing.x8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetTitle(l10n.themeSheetTitle),
                    _SheetOptionTile(
                      selected: current == ThemeMode.system,
                      title: l10n.themeSystem,
                      onTap: () => select(ThemeMode.system),
                    ),
                    _SheetOptionTile(
                      selected: current == ThemeMode.light,
                      title: l10n.themeLight,
                      onTap: () => select(ThemeMode.light),
                    ),
                    _SheetOptionTile(
                      selected: current == ThemeMode.dark,
                      title: l10n.themeDark,
                      onTap: () => select(ThemeMode.dark),
                    ),
                    SizedBox(height: theme.spacing.x10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Future<void> _showLanguageSheet(BuildContext context) async {
    final cubit = context.read<AppSettingsCubit>();
    final theme = Theme.of(context);
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.spacing.x8),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
            bloc: cubit,
            builder: (context, settings) {
              final current = settings.locale?.languageCode;
              void select(Locale? locale) {
                cubit.setLocale(locale);
                Navigator.of(context).pop();
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.spacing.x12,
                  0,
                  theme.spacing.x12,
                  theme.spacing.x8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetTitle(l10n.languageSheetTitle),
                    _SheetOptionTile(
                      selected: current == null,
                      title: l10n.themeSystem,
                      onTap: () => select(null),
                    ),
                    _SheetOptionTile(
                      selected: current == 'es',
                      title: l10n.languageSpanish,
                      onTap: () => select(const Locale('es')),
                    ),
                    _SheetOptionTile(
                      selected: current == 'en',
                      title: l10n.languageEnglish,
                      onTap: () => select(const Locale('en')),
                    ),
                    SizedBox(height: theme.spacing.x10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.x8,
        theme.spacing.x6,
        theme.spacing.x8,
        theme.spacing.x10,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: theme.textTheme.titleMedium),
      ),
    );
  }
}

class _SheetOptionTile extends StatelessWidget {
  const _SheetOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withOpacity(0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(theme.spacing.x4),
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.spacing.x4),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.x14,
            vertical: theme.spacing.x14,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
                SizedBox(width: theme.spacing.x12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
