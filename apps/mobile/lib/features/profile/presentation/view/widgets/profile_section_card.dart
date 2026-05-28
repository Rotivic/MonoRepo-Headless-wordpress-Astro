import 'package:flutter/material.dart';
import 'package:tcg_platform_mobile/theme/app_shadows.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: theme.spacing.x4,
            bottom: theme.spacing.x8,
          ),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: theme.extension<AppShadows>()?.standard ?? [],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
