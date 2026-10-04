import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_state.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.food});

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

    // การ์ดขาวมุมโค้ง 20 ไม่มีเงา เหมือนการ์ดอาหารหน้า Home
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FoodDetailPage(foodsId: food.idfoods, showComments: true),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: รูปโปรไฟล์ + ชื่อ + เวลา ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
                child: Row(
                  children: [
                    // รูปโปรไฟล์
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFFF3E0),
                      backgroundImage:
                          (food.creatorAvatar != null &&
                              food.creatorAvatar!.isNotEmpty)
                          ? NetworkImage(food.creatorAvatar!)
                          : null,
                      child:
                          (food.creatorAvatar == null ||
                              food.creatorAvatar!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 20,
                              color: Color(0xFFE64A19),
                            )
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
                              color: ProfileColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (timeLabel.isNotEmpty)
                            Text(
                              timeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ProfileColors.muted,
                                fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (food.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        food.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ProfileColors.ink,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],

                    // รูปเล็กใต้คำอธิบาย เฉพาะสูตรที่ติ๊ก "แสดงรูปในชุมชน"
                    if (food.showImgCommu && food.filePathImage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          food.filePathImage,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 120,
                            height: 90,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Container(height: 1, color: Colors.grey.shade200),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _PostFavoriteButton(food: food),

                        const SizedBox(width: 16),

                        _PostCommentButton(food: food),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCommentButton extends StatefulWidget {
  const _PostCommentButton({required this.food});

  final Food food;

  @override
  State<_PostCommentButton> createState() => _PostCommentButtonState();
}

class _PostCommentButtonState extends State<_PostCommentButton> {
  late int _commentCount = widget.food.commentCount;

  @override
  void didUpdateWidget(covariant _PostCommentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food.idfoods != widget.food.idfoods ||
        oldWidget.food.commentCount != widget.food.commentCount) {
      _commentCount = widget.food.commentCount;
    }
  }

  void _setCommentCount(int count) => setState(() => _commentCount = count);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'ดูความคิดเห็น',
      visualDensity: VisualDensity.compact,
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => FoodDetailPage(
            foodsId: widget.food.idfoods,
            scrollToComments: true,
            onCommentCountChanged: _setCommentCount,
          ),
        ),
      ),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 21,
            color: ProfileColors.muted,
          ),
          const SizedBox(width: 5),
          Text(
            '$_commentCount',
            style: const TextStyle(
              color: ProfileColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostFavoriteButton extends StatefulWidget {
  const _PostFavoriteButton({required this.food});

  final Food food;

  @override
  State<_PostFavoriteButton> createState() => _PostFavoriteButtonState();
}

class _PostFavoriteButtonState extends State<_PostFavoriteButton> {
  bool? _favoriteAtCountLoad;

  @override
  void didUpdateWidget(covariant _PostFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food.idfoods != widget.food.idfoods ||
        oldWidget.food.favoriteCount != widget.food.favoriteCount) {
      _favoriteAtCountLoad = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeId = widget.food.idfoods;

    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (previous, current) =>
          previous.isFavorite(recipeId) != current.isFavorite(recipeId) ||
          previous.isPending(recipeId) != current.isPending(recipeId) ||
          previous.status != current.status,
      builder: (context, state) {
        final isFavorite = state.isFavorite(recipeId);
        if (_favoriteAtCountLoad == null &&
            state.status == FavoriteStatus.ready) {
          _favoriteAtCountLoad = state.isPending(recipeId)
              ? !isFavorite
              : isFavorite;
        }

        final favoriteDelta =
            _favoriteAtCountLoad == null || isFavorite == _favoriteAtCountLoad
            ? 0
            : isFavorite
            ? 1
            : -1;
        final favoriteCount = (widget.food.favoriteCount + favoriteDelta).clamp(
          0,
          0x7fffffff,
        );

        return IconButton(
          onPressed: state.isPending(recipeId)
              ? null
              : () async {
                  final favoriteBloc = context.read<FavoriteBloc>();
                  if (await _requireSignIn(context)) return;
                  favoriteBloc.add(FavoriteToggled(recipeId));
                },
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
          tooltip: isFavorite ? 'เอาออกจากรายการโปรด' : 'บันทึกลงรายการโปรด',
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 22,
                color: isFavorite ? Colors.redAccent : ProfileColors.muted,
              ),
              const SizedBox(width: 5),
              Text(
                '$favoriteCount',
                style: const TextStyle(
                  color: ProfileColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<bool> _requireSignIn(BuildContext context) async {
  final navigator = Navigator.of(context);
  final accessToken = await TokenStorage().readAccessToken();

  if (accessToken != null && accessToken.trim().isNotEmpty) return false;
  if (!context.mounted) return true;

  navigator.pushNamed(AppRoutes.login);
  return true;
}
