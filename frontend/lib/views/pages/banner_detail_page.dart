import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/banner_item.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

/// หน้ารายละเอียดของแบนเนอร์ (AppBar ใช้ชื่อว่า Event)
class BannerDetailPage extends StatelessWidget {
  const BannerDetailPage({super.key, required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    final period = _formatPeriod(banner.startDate, banner.endDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade500,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (banner.title.isNotEmpty) ...[
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (period != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: FoodDetailColors.softOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: 18,
                        color: FoodDetailColors.accentOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        period,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: FoodDetailColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                banner.description.isNotEmpty
                    ? banner.description
                    : 'ยังไม่มีรายละเอียดของกิจกรรมนี้',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// แสดงช่วงวันที่ของ event เช่น 1/10/2026 - 31/10/2026
  static String? _formatPeriod(DateTime? start, DateTime? end) {
    String format(DateTime d) => '${d.day}/${d.month}/${d.year}';

    if (start != null && end != null) {
      return '${format(start)} - ${format(end)}';
    }
    if (start != null) return 'เริ่ม ${format(start)}';
    if (end != null) return 'ถึง ${format(end)}';
    return null;
  }
}
