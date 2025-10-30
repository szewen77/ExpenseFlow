import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _NavIcon(FontAwesomeIcons.house, label: 'Home'),
      _NavIcon(FontAwesomeIcons.listUl, label: 'Transactions'),
      _NavIcon(FontAwesomeIcons.chartColumn, label: 'Reports'),
      _NavIcon(FontAwesomeIcons.gear, label: 'Settings'),
    ];

    final Color pill = Theme.of(context).colorScheme.primary.withAlpha(32);
    final Color selectedColor = Theme.of(context).colorScheme.primary;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: Colors.transparent,
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelected,
        height: 64,
        destinations: List.generate(navItems.length, (i) {
          final item = navItems[i];
          final selected = i == currentIndex;
          return NavigationDestination(
            icon: _AnimatedNavIcon(
              icon: item.icon,
              selected: selected,
              color: selectedColor,
              pillColor: pill,
            ),
            label: item.label,
          );
        }),
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final Color pillColor;
  const _AnimatedNavIcon({required this.icon, required this.selected, required this.color, required this.pillColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: selected ? 44 : 0,
          height: selected ? 44 : 0,
          decoration: BoxDecoration(
            color: selected ? pillColor : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        AnimatedScale(
          scale: selected ? 1.18 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: selected ? 1 : 0.7,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              icon,
              size: selected ? 28 : 24,
              color: selected ? color : null,
              shadows: selected
                  ? [Shadow(offset: Offset(0, 2), blurRadius: 6, color: color.withOpacity(0.14))]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavIcon {
  final IconData icon;
  final String label;
  const _NavIcon(this.icon, {required this.label});
}


