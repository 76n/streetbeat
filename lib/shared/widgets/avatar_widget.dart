import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.radius = 24,
    this.name,
  });

  final double radius;
  final String? name;

  static String _initials(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.card,
      child: initials.isEmpty
          ? Icon(Icons.person, size: radius, color: AppColors.textSecondary)
          : Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.45,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
    );
  }
}
