import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/custom_text_field.dart';
import 'package:tcg_platform_mobile/features/profile/data/profile_repository.dart';
import 'package:tcg_platform_mobile/features/profile/domain/models/user_profile.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/cubit/edit_profile_state.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProfileCubit(context.read<ProfileRepository>()),
      child: EditProfileView(user: user),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, required this.user});

  final UserProfile user;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  File? _selectedAvatarFile;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);

    _emailController.addListener(_validateForm);
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _validateForm();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    setState(() {
      _isFormValid =
          emailRegex.hasMatch(email) && first.isNotEmpty && last.isNotEmpty;
    });
  }

  Future<void> _pickAvatar() async {
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

    if (source != null) {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => _selectedAvatarFile = File(picked.path));
        _validateForm();
      }
    }
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedUser = widget.user.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      );
      context.read<EditProfileCubit>().updateUser(
        updatedUser,
        avatarFile: _selectedAvatarFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final l10n = context.l10n;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: BlocConsumer<EditProfileCubit, EditProfileState>(
            listener: (context, state) {
              if (state is EditProfileSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              }
              if (state is EditProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is EditProfileLoading;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.x32,
                    vertical: spacing.x24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Header(),
                          SizedBox(height: spacing.headerGap),
                          Center(
                            child: _AvatarEdit(
                              imageUrl: widget.user.avatarUrl,
                              selectedAvatarFile: _selectedAvatarFile,
                              onTap: _pickAvatar,
                              backendBaseUrl: 'http://192.168.1.15:8000',
                            ),
                          ),
                          SizedBox(height: spacing.sectionGap),
                          CustomTextField(
                            label: l10n.profileLabelEmail,
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            hintText: 'example@gmail.com',
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.profileLabelFirstName,
                            controller: _firstNameController,
                            icon: Icons.badge_outlined,
                            enabled: !isLoading,
                            hintText: 'John',
                          ),
                          SizedBox(height: spacing.fieldGap),
                          CustomTextField(
                            label: l10n.profileLabelLastName,
                            controller: _lastNameController,
                            icon: Icons.badge_outlined,
                            enabled: !isLoading,
                            hintText: 'Doe',
                          ),
                          SizedBox(height: spacing.sectionGap),
                          FilledButton(
                            onPressed: (isLoading || !_isFormValid)
                                ? null
                                : _onSave,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.updateProfileCta),
                          ),
                          SizedBox(height: spacing.x24),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(l10n.commonBack),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      children: [
        Text(
          l10n.profileSectionPreferences.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.spacing.x12),
        Text(
          l10n.editProfileTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 32),
        ),
      ],
    );
  }
}

class _AvatarEdit extends StatelessWidget {
  const _AvatarEdit({
    required this.imageUrl,
    required this.selectedAvatarFile,
    required this.onTap,
    required this.backendBaseUrl,
  });

  final String? imageUrl;
  final File? selectedAvatarFile;
  final VoidCallback onTap;
  final String backendBaseUrl;

  String? _resolveImageUrl() {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    final backendUri = Uri.tryParse(backendBaseUrl);

    if (uri == null) return raw;

    if (!uri.hasScheme && backendUri != null) {
      final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
      return backendUri.replace(path: normalizedPath).toString();
    }

    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
    if (backendUri != null && localHosts.contains(uri.host)) {
      return uri
          .replace(
            scheme: backendUri.scheme,
            host: backendUri.host,
            port: backendUri.hasPort ? backendUri.port : uri.port,
          )
          .toString();
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullImageUrl = _resolveImageUrl();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Container(
                color: theme.colorScheme.surface,
                child: selectedAvatarFile != null
                    ? Image.file(selectedAvatarFile!, fit: BoxFit.cover)
                    : (fullImageUrl != null
                          ? Image.network(
                              fullImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person_outline,
                                    size: 52,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                  ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                            )
                          : Icon(
                              Icons.person_outline,
                              size: 52,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            )),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Theme.of(context).spacing.x8, 6, 8, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
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
