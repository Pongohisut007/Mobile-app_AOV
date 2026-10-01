import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/banner_rating/banner_rating_bloc.dart';
import 'package:flutter_application_1/bloc/banner_rating/banner_rating_state.dart';
import 'package:flutter_application_1/models/banner_item.dart';
import 'package:flutter_application_1/widgets/banner_detail/banner_detail_colors.dart';
import 'package:flutter_application_1/widgets/banner_detail/banner_rating_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// หน้ารายละเอียดของแบนเนอร์ (AppBar ใช้ชื่อว่า Event)
/// รูปเต็มหัว แล้วเนื้อหาเป็นการ์ดขอบมนซ้อนขึ้นมาบนรูป
class BannerDetailPage extends StatelessWidget {
  const BannerDetailPage({super.key, required this.banner});

  final BannerItem banner;

  static const _cardRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final period = _formatPeriod(banner.startDate, banner.endDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            centerTitle: true,
            backgroundColor: BannerDetailColors.primaryRed,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Event',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _HeaderImage(imageUrl: banner.imageUrl),
                  // ไล่สีดำจาง ๆ ด้านบนให้ปุ่มย้อนกลับกับคำว่า Event อ่านออก
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ขอบมนสีขาวด้านล่างรูป ทำให้เนื้อหาดูเหมือนการ์ดซ้อนขึ้นมา
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(_cardRadius),
              child: SizedBox(
                height: _cardRadius,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_cardRadius),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title.isNotEmpty ? banner.title : 'Event',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (period != null)
                        _InfoChip(icon: Icons.event_rounded, label: period),
                      const _AverageRatingChip(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('รายละเอียด'),
                  const SizedBox(height: 10),
                  Text(
                    banner.description.isNotEmpty
                        ? banner.description
                        : 'ยังไม่มีรายละเอียดของกิจกรรมนี้',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 24),
                  const _SectionTitle('คะแนนและรีวิว'),
                  const SizedBox(height: 14),
                  const BannerRatingSection(),
                ],
              ),
            ),
          ),
        ],
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

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: Colors.grey.shade200);
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade500,
          size: 48,
        ),
      ),
    );
  }
}

/// หัวข้อ section มีขีดสีแดงเล็ก ๆ ด้านหน้า
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: BannerDetailColors.primaryRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = BannerDetailColors.accentOrange,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BannerDetailColors.softOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// ป้าย ★ 4.5 · 12 รีวิว ข้างวันที่ ซ่อนไว้ถ้ายังไม่มีใครให้คะแนน
class _AverageRatingChip extends StatelessWidget {
  const _AverageRatingChip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerRatingBloc, BannerRatingState>(
      buildWhen: (previous, current) => previous.summary != current.summary,
      builder: (context, state) {
        final summary = state.summary;
        if (summary.count == 0) return const SizedBox.shrink();

        return _InfoChip(
          icon: Icons.star_rounded,
          label:
              '${summary.average.toStringAsFixed(1)} · ${summary.count} รีวิว',
          color: const Color(0xFFE65100),
        );
      },
    );
  }
}
