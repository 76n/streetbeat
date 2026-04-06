import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentShellIndex,
    required this.onShellTabSelected,
    required this.onRunPressed,
  });

  final int currentShellIndex;
  final ValueChanged<int> onShellTabSelected;
  final VoidCallback onRunPressed;

  static const _inactive = AppColors.textSecondary;
  static const _active = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  emoji: '🏠',
                  label: 'Feed',
                  selected: currentShellIndex == 0,
                  activeColor: _active,
                  inactiveColor: _inactive,
                  onTap: () => onShellTabSelected(0),
                ),
              ),
              Expanded(
                child: Center(
                  child: _RunFab(onTap: onRunPressed),
                ),
              ),
              Expanded(
                child: _NavItem(
                  emoji: '🏆',
                  label: 'Board',
                  selected: currentShellIndex == 1,
                  activeColor: _active,
                  inactiveColor: _inactive,
                  onTap: () => onShellTabSelected(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  emoji: '👤',
                  label: 'Profile',
                  selected: currentShellIndex == 2,
                  activeColor: _active,
                  inactiveColor: _inactive,
                  onTap: () => onShellTabSelected(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = selected ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: selected ? 24 : 22)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunFab extends StatelessWidget {
  const _RunFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      elevation: 6,
      shadowColor: AppColors.primary.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 58,
          height: 58,
          child: Center(
            child: Text(
              '▶️',
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }
}
