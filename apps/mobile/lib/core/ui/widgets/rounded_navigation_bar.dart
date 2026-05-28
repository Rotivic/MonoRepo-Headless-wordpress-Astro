import 'package:flutter/material.dart';
import 'package:tcg_platform_mobile/theme/app_shadows.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class RoundedNavigationBar extends StatelessWidget {
  const RoundedNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.height = 72,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.spacing.x8),
          topRight: Radius.circular(theme.spacing.x8),
        ),
        boxShadow: theme.extension<AppShadows>()?.standard ?? [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.spacing.x8),
          topRight: Radius.circular(theme.spacing.x8),
        ),
        child: NavigationBar(
          height: height,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primary.withOpacity(0.08),
          selectedIndex: selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations.map((d) {
            return NavigationDestination(
              icon: IconTheme(
                data: IconThemeData(
                  color: isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurfaceVariant,
                ),
                child: d.icon,
              ),
              selectedIcon: IconTheme(
                data: IconThemeData(color: theme.colorScheme.primary),
                child: d.selectedIcon ?? d.icon,
              ),
              label: d.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}
