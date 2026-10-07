import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import 'exit_confirm_scope.dart';

/// Home · Appointments · Find Healthcare · Profile. Each tab keeps its own
/// navigation stack and scroll position.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return ExitConfirmScope(
      child: Scaffold(
        body: shell,
        bottomNavigationBar: CityCareBottomNavigation(
          currentIndex: shell.currentIndex,
          onSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
    );
  }
}

/// Floating white bar: blue active pill, a tiny lime dot under the active
/// tab (so selection never relies on colour alone), muted inactive icons.
class CityCareBottomNavigation extends StatelessWidget {
  const CityCareBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
      'Appointments',
    ),
    (Icons.search_rounded, Icons.manage_search_rounded, 'Find'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: CityCareColors.surface,
          borderRadius: BorderRadius.circular(CityCareRadius.xl),
          border: Border.all(color: CityCareColors.border),
          boxShadow: CityCareShadows.soft,
        ),
        child: Row(
          children: [
            for (final (i, item) in _items.indexed)
              Expanded(
                child: _NavItem(
                  key: ValueKey('nav:${item.$3}'),
                  icon: item.$1,
                  selectedIcon: item.$2,
                  label: item.$3,
                  selected: i == currentIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? CityCareColors.primaryDark
        : CityCareColors.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(CityCareRadius.lg),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 18 : 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? CityCareColors.primarySoft
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(CityCareRadius.pill),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected ? 1 : 0,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: CityCareColors.lime,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x4012324A), blurRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
