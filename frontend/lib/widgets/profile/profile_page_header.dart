import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({super.key, required this.onSettingsPressed});

  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: ProfileColors.ink,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Your recipes, orders and preferences',
                style: TextStyle(
                  color: ProfileColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: onSettingsPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ProfileColors.ink,
            fixedSize: const Size(46, 46),
          ),
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}
