import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({super.key, this.radius = 24});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.card,
      child: Icon(Icons.person, size: radius, color: AppColors.textSecondary),
    );
  }
}
