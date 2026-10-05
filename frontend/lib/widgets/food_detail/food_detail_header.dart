import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/common/app_shadows.dart';

import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/food_image.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class FoodDetailHeader extends StatefulWidget {
  const FoodDetailHeader({
    super.key,
    required this.food,
    this.onEdit,
    this.onDelete,
    this.isBusy = false,
  });

  final Food food;

  /// กำลังเปิดหน้าแก้ไขหรือกำลังลบ: แสดงตัวหมุนแทนเมนู กันกดซ้ำ
  final bool isBusy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<FoodDetailHeader> createState() => _FoodDetailHeaderState();
}

class _FoodDetailHeaderState extends State<FoodDetailHeader> {
  bool _isOwner = false;
  bool _isCheckingOwner = true;

  // สูตร official ที่เผยแพร่แล้วไม่มีเมนูแก้ไข
  bool get _canEdit =>
      !(widget.food.type == 'official' && widget.food.status == 'published');

  @override
  void initState() {
    super.initState();
    _checkOwner();
  }

  Future<void> _checkOwner() async {
    final currentUserId = await TokenStorage().readUserId();

    if (!mounted) return;

    setState(() {
      _isOwner =
          currentUserId != null &&
          currentUserId.trim().isNotEmpty &&
          currentUserId == widget.food.creatorId;

      _isCheckingOwner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // รูปอาหารเต็มความกว้าง ปุ่มลอยทับด้านบน
        FoodImage(
          heroTag: widget.food.idfoods,
          imageUrl: widget.food.filePathImage,
        ),

        // ปุ่มย้อนกลับ
        Positioned(
          top: 10,
          left: 10,
          child: _FloatingCircle(
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: FoodDetailColors.primaryRed,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),

        // ปุ่ม 3 จุด
        if (!_isCheckingOwner && _isOwner)
          Positioned(
            top: 10,
            right: 10,
            child: _FloatingCircle(
              child: widget.isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: FoodDetailColors.primaryRed,
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: FoodDetailColors.primaryRed,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            widget.onEdit?.call();
                            break;

                          case 'delete':
                            widget.onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (_canEdit)
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 12),
                                Text(context.l10n.edit),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                context.l10n.deleteRecipe,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}

/// ปุ่มวงกลมขาวลอยทับรูป มีเงาให้เห็นชัดทั้งบนรูปสีเข้มและสีอ่อน
class _FloatingCircle extends StatelessWidget {
  const _FloatingCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppShadows.chip,
      ),
      child: child,
    );
  }
}
