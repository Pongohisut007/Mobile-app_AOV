import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/community/category_card.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.grey.shade100,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CategoryCard(),
          ],
        ),
      ),
    ),
    );
  }
}
