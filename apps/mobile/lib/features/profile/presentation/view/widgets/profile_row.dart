import 'package:flutter/material.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class ProfileRow extends StatelessWidget {
  const ProfileRow._({
    required this.icon,
    required this.title,
    required this.value,
    required this.isAction,
    this.onTap,
  });

  factory ProfileRow.readOnly({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ProfileRow._(
      icon: icon,
      title: title,
      value: value,
      isAction: false,
    );
  }

  factory ProfileRow.action({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ProfileRow._(
      icon: icon,
      title: title,
      value: value,
      isAction: true,
      onTap: onTap,
    );
  }

  final IconData icon;
  final String title;
  final String value;
  final bool isAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;

    final child = Padding(
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
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: spacing.x12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          if (isAction) ...[
            SizedBox(width: spacing.x8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.outlineVariant,
              size: 20,
            ),
          ],
        ],
      ),
    );

    if (!isAction) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
