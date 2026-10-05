import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/route_transition_aware.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/recipe_review.dart';
import 'package:flutter_application_1/repositories/recipe_review_repository.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_section.dart';
import 'package:flutter_application_1/widgets/recipe_review/recipe_review_tile.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

/// หน้ารีวิวทั้งหมดของสูตร เลื่อนลงสุดแล้วโหลดหน้าถัดไปเอง
class RecipeReviewsPage extends StatefulWidget {
  const RecipeReviewsPage({
    super.key,
    required this.recipeId,
    required this.summary,
    this.repository,
  });

  final String recipeId;

  /// คะแนนเฉลี่ยจากหน้าสูตร โชว์ไปก่อนระหว่างโหลดค่าล่าสุดจาก API
  final RecipeReviewSummary summary;

  final RecipeReviewRepository? repository;

  @override
  State<RecipeReviewsPage> createState() => _RecipeReviewsPageState();
}

class _RecipeReviewsPageState extends State<RecipeReviewsPage>
    with RouteTransitionAware {
  static const _pageSize = 20;

  late final RecipeReviewRepository _repository =
      widget.repository ??
      HttpRecipeReviewRepository(baseUrl: ApiConfig.apiBaseUrl);

  late RecipeReviewSummary _summary = widget.summary;
  final List<RecipeReview> _reviews = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  // เพิ่มทุกครั้งที่ refresh ผลของ _loadMore ที่ยิงก่อนหน้าจะถูกทิ้ง กันรีวิวซ้ำ
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _loadSummary();
  }

  // ค่าที่ส่งมาจากหน้าสูตรอาจเก่าแล้ว (เช่นมีคนรีวิวเพิ่ม) จึงโหลดใหม่เสมอ
  // โหลดไม่ได้ก็ใช้ค่าเดิมต่อ ไม่ต้องขึ้น error
  Future<void> _loadSummary() async {
    try {
      // ผลมาก่อนเลื่อนหน้าเสร็จ = รอให้เสร็จก่อนค่อยวาด (หลังจากนั้นไม่ต้องรอ)
      final summary = await afterRouteTransition(
        _repository.fetchSummary(widget.recipeId),
      );
      if (!mounted) return;
      setState(() => _summary = summary);
    } on Exception catch (_) {
      // ใช้ค่าเดิม
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await afterRouteTransition(
        _repository.fetchReviewPage(
          widget.recipeId,
          page: _page + 1,
          limit: _pageSize,
        ),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _page = result.page;
        _hasMore = result.hasMore;
        _reviews.addAll(result.items);
      });
    } on Exception catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  // ดึงลงเพื่อโหลดรีวิวหน้าแรกใหม่ โหลดพลาดก็โชว์รายการเดิมไว้
  Future<void> _refresh() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final summaryLoaded = _loadSummary();
    try {
      final result = await _repository.fetchReviewPage(
        widget.recipeId,
        page: 1,
        limit: _pageSize,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _page = result.page;
        _hasMore = result.hasMore;
        _reviews
          ..clear()
          ..addAll(result.items);
      });
    } on Exception catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
    await summaryLoaded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.l10n.allReviews,
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
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            // +1 หัวการ์ดคะแนน, +1 ท้ายรายการ (กำลังโหลด/ผิดพลาด/หมดแล้ว)
            itemCount: _reviews.length + 2,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 20 : 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return RecipeReviewSummaryCard(
                  summary: _summary,
                  title: context.l10n.averageRating,
                );
              }
              if (index <= _reviews.length) {
                return RecipeReviewTile(review: _reviews[index - 1]);
              }
              return _buildFooter();
            },
          ),
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
              label: Text(context.l10n.retry),
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
            context.l10n.noReviewsYet,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
