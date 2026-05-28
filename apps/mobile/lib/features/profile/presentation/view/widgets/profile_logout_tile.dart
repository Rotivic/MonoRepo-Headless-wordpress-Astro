import 'package:flutter/material.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_shadows.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class ProfileLogoutTile extends StatelessWidget {
  const ProfileLogoutTile({
    super.key,
    required this.onLogout,
    required this.color,
  });

  final Future<void> Function() onLogout;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.extension<AppShadows>()?.standard ?? [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onLogout,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.x16,
              vertical: spacing.x14,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.logout_rounded, color: color, size: 20),
                ),
                SizedBox(width: spacing.x12),
                Expanded(
                  child: Text(
                    l10n.profileLogoutCta,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
