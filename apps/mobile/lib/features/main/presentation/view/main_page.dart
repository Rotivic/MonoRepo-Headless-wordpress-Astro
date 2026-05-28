import 'package:flutter/material.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/auth_background.dart';
import 'package:tcg_platform_mobile/core/ui/widgets/rounded_navigation_bar.dart';
import 'package:tcg_platform_mobile/features/authentication/domain/models/user.dart';
import 'package:tcg_platform_mobile/features/home/presentation/view/home_page.dart';
import 'package:tcg_platform_mobile/features/profile/presentation/view/profile_page.dart';
import 'package:tcg_platform_mobile/l10n/l10n.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  late User _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    _user = args is User
        ? args
        : User(
            id: 0,
            email: null,
            firstName: null,
            lastName: null,
            enabled: false,
            isVerified: false,
          );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final pages = [
      HomePage(user: _user),
      const ProfilePage(),
    ];

    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: pages[_currentIndex],
        bottomNavigationBar: RoundedNavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: const Icon(Icons.description),
              label: l10n.tabDocuments,
            ),
            NavigationDestination(
              icon: const Icon(Icons.list_alt_outlined),
              selectedIcon: const Icon(Icons.list_alt),
              label: l10n.tabCheckins,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.tabProfile,
            ),
          ],
        ),
      ),
    );
  }
}
