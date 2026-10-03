import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';
import 'package:flutter_application_1/widgets/food_detail/food_image.dart';

class FoodDetailHeader extends StatefulWidget {
  const FoodDetailHeader({
    super.key,
    required this.food,
    this.onEdit,
    this.onDelete,
  });

  final Food food;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<FoodDetailHeader> createState() => _FoodDetailHeaderState();
}

class _FoodDetailHeaderState extends State<FoodDetailHeader> {
  bool _isOwner = false;
  bool _isCheckingOwner = true;

  @override
  void initState() {
    super.initState();
    _checkOwner();
  }

  Future<void> _checkOwner() async {
    final currentUserId = await TokenStorage().readUserId();

    if (!mounted) return;

    setState(() {
      _isOwner = currentUserId != null &&
          currentUserId.trim().isNotEmpty &&
          currentUserId == widget.food.creatorId;

      _isCheckingOwner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // พื้นหลัง
        Container(
          height: 320,
          decoration: const BoxDecoration(
            color: FoodDetailColors.softOrange,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),

        // รูปอาหาร
        SizedBox(
          height: 320,
          child: Center(
            child: FoodImage(
              heroTag: widget.food.idfoods,
              imageUrl: widget.food.filePathImage,
            ),
          ),
        ),

        // ปุ่มย้อนกลับ
        Positioned(
          top: 10,
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white,
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
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: PopupMenuButton<String>(
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
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text('แก้ไข'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ลบสูตรอาหาร',
                          style: TextStyle(
                            color: Colors.red,
                          ),
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