import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(value: '12', label: 'Recipes'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(value: '28', label: 'Saved'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(value: '4.9', label: 'Rating'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: ProfileColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: ProfileColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
