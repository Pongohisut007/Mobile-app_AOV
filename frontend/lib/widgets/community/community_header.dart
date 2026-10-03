import 'package:flutter/material.dart';

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
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Community',
            style: TextStyle(
              fontSize: isIpad ? 30 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            iconSize: isIpad ? 30 : 24,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}