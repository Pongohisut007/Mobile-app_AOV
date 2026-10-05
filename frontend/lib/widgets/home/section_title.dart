import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.onSeeMore, super.key});

  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Recommended",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onSeeMore,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text("See More"),
        ),
      ],
    );
  }
}
