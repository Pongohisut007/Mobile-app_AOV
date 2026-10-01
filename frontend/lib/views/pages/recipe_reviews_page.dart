import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/recipe_review.dart';
import 'package:flutter_application_1/repositories/recipe_review_repository.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_section.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_tile.dart';

/// หน้ารีวิวทั้งหมดของสูตร เลื่อนลงสุดแล้วโหลดหน้าถัดไปเอง
class RecipeReviewsPage extends StatefulWidget {
  const RecipeReviewsPage({
    super.key,
    required this.recipeId,
    required this.summary,
    this.repository,
  });

  final String recipeId;

  /// คะแนนเฉลี่ยจากหน้าสูตร เอามาโชว์หัวหน้าได้เลยไม่ต้องโหลดซ้ำ
  final RecipeReviewSummary summary;

  final RecipeReviewRepository? repository;

  @override
  State<RecipeReviewsPage> createState() => _RecipeReviewsPageState();
}

class _RecipeReviewsPageState extends State<RecipeReviewsPage> {
  static const _pageSize = 20;

  late final RecipeReviewRepository _repository =
      widget.repository ??
      HttpRecipeReviewRepository(baseUrl: ApiConfig.apiBaseUrl);

  final List<RecipeReview> _reviews = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _repository.fetchReviewPage(
        widget.recipeId,
        page: _page + 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _hasMore = result.hasMore;
        _reviews.addAll(result.items);
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'รีวิวทั้งหมด',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: NotificationListener<ScrollNotification>(
        // ใกล้ถึงล่างสุดแล้วโหลดหน้าถัดไป
        onNotification: (notification) {
          // โหลดพลาดแล้วไม่ยิงซ้ำเองตอนเลื่อน ให้กดลองใหม่แทน
          if (_error == null && notification.metrics.extentAfter < 300) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          // +1 หัวการ์ดคะแนน, +1 ท้ายรายการ (กำลังโหลด/ผิดพลาด/หมดแล้ว)
          itemCount: _reviews.length + 2,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? 20 : 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return RecipeReviewSummaryCard(
                summary: widget.summary,
                title: 'คะแนนเฉลี่ย',
              );
            }
            if (index <= _reviews.length) {
              return RecipeReviewTile(review: _reviews[index - 1]);
            }
            return _buildFooter();
          },
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }
    if (_reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'ยังไม่มีรีวิว',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
