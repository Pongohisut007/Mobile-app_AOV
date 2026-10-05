import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.onSeeMore, super.key});

  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.recommendedTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onSeeMore,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(context.l10n.seeMore),
        ),
      ],
    );
  }
}
