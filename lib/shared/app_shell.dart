import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import 'exit_confirm_scope.dart';

/// Bottom navigation: Home · Appointments · Find Healthcare · Profile.
/// Each tab keeps its own navigation stack and scroll position. The bar is a
/// floating rounded card, docked below content so it never covers anything.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return ExitConfirmScope(
      child: Scaffold(
        body: shell,
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: ClinicColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: ClinicColors.border),
              boxShadow: ClinicShadows.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              height: 66,
              indicatorShape: const StadiumBorder(),
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Appointments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  selectedIcon: Icon(Icons.manage_search_rounded),
                  label: 'Find',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
