import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.onEditPressed});

  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProfileColors.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: ProfileColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/images/Profile1.jpg'),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chef Mook',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'chef@recipy.local',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    SizedBox(height: 10),
                    _CreatorBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onEditPressed,
              style: FilledButton.styleFrom(
                backgroundColor: ProfileColors.accent,
                foregroundColor: ProfileColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: const Text(
                'Edit profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorBadge extends StatelessWidget {
  const _CreatorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: ProfileColors.accent, size: 15),
          SizedBox(width: 5),
          Text(
            'Recipe creator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
