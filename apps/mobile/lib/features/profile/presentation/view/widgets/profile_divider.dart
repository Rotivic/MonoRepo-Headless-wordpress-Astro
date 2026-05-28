import 'package:flutter/material.dart';

class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1,
        thickness: 1,
        color: cs.outlineVariant.withOpacity(0.35),
      ),
    );
  }
}
