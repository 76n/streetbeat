import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentShellIndex,
    required this.onShellTabSelected,
    required this.onRunPressed,
    this.feedBadgeCount = 0,
  });

  final int currentShellIndex;
  final ValueChanged<int> onShellTabSelected;
  final VoidCallback onRunPressed;
  final int feedBadgeCount;

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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Feed',
                  selected: currentShellIndex == 0,
                  activeColor: _active,
                  inactiveColor: _inactive,
                  badgeCount: feedBadgeCount,
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
                  icon: Icons.emoji_events_rounded,
                  label: 'Board',
                  selected: currentShellIndex == 1,
                  activeColor: _active,
                  inactiveColor: _inactive,
                  onTap: () => onShellTabSelected(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded,
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

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.selected ? widget.activeColor : widget.inactiveColor;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      widget.icon,
                      size: widget.selected ? 26 : 24,
                      color: c,
                    ),
                    if (widget.badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            '${widget.badgeCount > 9 ? '9+' : widget.badgeCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RunFab extends StatefulWidget {
  const _RunFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RunFab> createState() => _RunFabState();
}

class _RunFabState extends State<_RunFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: AppColors.primary,
          elevation: _pressed ? 4 : 10,
          shadowColor: AppColors.primary.withValues(alpha: 0.55),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 38,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
