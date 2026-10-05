import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';

class EmptySteps extends StatelessWidget {
  const EmptySteps({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppShadows.card,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 54, color: Color(0xFF6D55A5)),
            SizedBox(height: 14),
            Text(
              'สูตรนี้ยังไม่มีขั้นตอนการทำ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
