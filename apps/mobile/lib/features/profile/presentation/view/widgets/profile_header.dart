import 'package:flutter/material.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.title,
    required this.name,
    required this.subtitle,
    required this.role,
    required this.employeeId,
    required this.onEditPressed,
    required this.onChangePhotoPressed,
    this.imageUrl,
    this.backendBaseUrl,
    this.onBackPressed,
  });

  final String title;
  final String name;
  final String subtitle;
  final String role;
  final String employeeId;
  final String? imageUrl;
  final String? backendBaseUrl;
  final VoidCallback onEditPressed;
  final VoidCallback onChangePhotoPressed;
  final VoidCallback? onBackPressed;

  String? _resolveImageUrl() {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    final backendUri = backendBaseUrl != null
        ? Uri.tryParse(backendBaseUrl!)
        : null;

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
    final spacing = theme.spacing;
    final l10n = context.l10n;
    final fullImageUrl = _resolveImageUrl();

    return Column(
      children: [
        // Top Margin
        SizedBox(height: spacing.x24),

        // Consistent Header Pattern
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.x12),
        Text(
          l10n.profileAccountInfo,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 32),
        ),

        SizedBox(height: spacing.headerGap),

        // Avatar
        Stack(
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
                  child: fullImageUrl != null
                      ? Image.network(
                          fullImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_outline,
                            size: 52,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
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
                        ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: theme.colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onChangePhotoPressed,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.x24),

        // Name & Subtitle
        Text(
          name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: spacing.x4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        SizedBox(height: spacing.x18),

        // Info Chips
        Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing.x8,
          runSpacing: spacing.x8,
          children: [
            _InfoChip(text: role),
            _InfoChip(text: l10n.profileEmployeeId(employeeId)),
          ],
        ),
        SizedBox(height: spacing.x24),

        // Action Button
        OutlinedButton(
          onPressed: onEditPressed,
          child: Text(l10n.editProfileTitle),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
