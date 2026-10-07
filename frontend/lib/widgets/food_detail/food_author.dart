import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/app_network_image.dart';
import 'package:flutter_application_1/widgets/food_detail/food_detail_colors.dart';

/// รูปโปรไฟล์ + ชื่อผู้เขียนสูตร ใต้ชื่อสูตร (ไม่มีชื่อ = ใช้ "ผู้ใช้งาน" เหมือนการ์ด community)
class FoodAuthor extends StatelessWidget {
  const FoodAuthor({super.key, this.name, this.avatarUrl});

  final String? name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl;
    final hasAvatar = avatar != null && avatar.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: FoodDetailColors.softOrange,
          backgroundImage: hasAvatar
              ? appNetworkImageProvider(context, avatar, logicalSize: 28)
              : null,
          child: hasAvatar
              ? null
              : const Icon(
                  Icons.person,
                  size: 16,
                  color: FoodDetailColors.accentOrange,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name ?? context.l10n.anonymousUser,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
