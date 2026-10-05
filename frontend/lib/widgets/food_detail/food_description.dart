import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// หัวข้อ "Description" + รายละเอียดเมนู
class FoodDescription extends StatelessWidget {
  const FoodDescription({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.description,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
