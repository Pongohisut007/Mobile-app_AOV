import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.food,
  });

  final Food food;

  // แปลง DateTime → "x นาทีที่แล้ว / x ชั่วโมงที่แล้ว / x วันที่แล้ว"
  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 30) return '${diff.inDays} วันที่แล้ว';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} เดือนที่แล้ว';
    return '${(diff.inDays / 365).floor()} ปีที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _timeAgo(food.publishedAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: รูปโปรไฟล์ + ชื่อ + เวลา ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // รูปโปรไฟล์
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: (food.creatorAvatar != null &&
                          food.creatorAvatar!.isNotEmpty)
                      ? NetworkImage(food.creatorAvatar!)
                      : null,
                  child: (food.creatorAvatar == null ||
                          food.creatorAvatar!.isEmpty)
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),

                // ชื่อ + เวลา
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.creatorName ?? 'ผู้ใช้งาน',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── ชื่ออาหาร + หมวดหมู่ + คำอธิบาย ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (food.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    food.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (food.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    food.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}