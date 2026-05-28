import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';
import 'package:tcg_platform_mobile/theme/app_spacing.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.spacing;
    final l10n = context.l10n;

    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat.yMMMMEEEEd(locale).add_Hms().format(_now);

    final userName = (widget.user.firstName ?? '').trim();
    final welcomeText = userName.isNotEmpty
        ? l10n.homeWelcomeNamed(userName)
        : l10n.homeWelcome;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.x32),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  welcomeText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium,
                ),
                SizedBox(height: spacing.x12),
                Text(
                  formattedDate,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: spacing.x24),
                Text(
                  l10n.homeBuildFun,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: spacing.x24),
            child: Text(
              l10n.homeCopyright(_now.year),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
