import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.food,
  });

  final Food food;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่ออาหาร
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // หมวดหมู่
                if (food.category.isNotEmpty)
                  Text(
                    food.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 6),
                // คำอธิบาย
                if (food.description.isNotEmpty)
                  Text(
                    food.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}