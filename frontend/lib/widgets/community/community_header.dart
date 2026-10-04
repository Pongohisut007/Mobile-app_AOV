import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

/// หัวหน้า community หน้าตาเดียวกับหัวหน้า Profile
class CommunityHeader extends StatelessWidget {
  const CommunityHeader({
    super.key,
    required this.isIpad,
    required this.onAddPressed,
  });

  final bool isIpad;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community',
                style: TextStyle(
                  color: ProfileColors.ink,
                  fontSize: isIpad ? 34 : 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: onAddPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ProfileColors.ink,
            fixedSize: const Size(46, 46),
          ),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Create recipe',
        ),
      ],
    );
  }
}
