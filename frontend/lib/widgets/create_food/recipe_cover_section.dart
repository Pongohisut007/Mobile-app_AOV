import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_section_heading.dart';
import 'package:flutter_application_1/widgets/create_food/recipe_form_style.dart';

class RecipeCoverSection extends StatelessWidget {
  const RecipeCoverSection({
    super.key,
    required this.coverFile,
    required this.fileName,
    this.coverUrl,
    required this.showImgCommu,
    required this.isBusy,
    required this.isSaving,
    required this.isPickingFile,
    required this.isUploading,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onShowImgCommuChanged,
    this.showImgCommuOption = true,
  });

  // สูตร official ไม่ได้ขึ้นในชุมชน จึงซ่อนตัวเลือกนี้
  final bool showImgCommuOption;

  final File? coverFile;
  final String? fileName;
  // รูปเดิมที่อัปโหลดไว้แล้ว (ตอนแก้ไขสูตร) แสดงเมื่อยังไม่ได้เลือกไฟล์ใหม่
  final String? coverUrl;
  final bool showImgCommu;

  final bool isBusy;
  final bool isSaving;
  final bool isPickingFile;
  final bool isUploading;

  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final ValueChanged<bool> onShowImgCommuChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = isSaving || isBusy;
    final hasCover = coverFile != null || coverUrl != null;
    final loading = isPickingFile || isUploading;

    return RecipeFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RecipeFormSectionHeading(
            title: 'รูปตัวอย่างอาหาร',
            subtitle: 'รูปหน้าปกที่ทุกคนจะเห็นก่อน',
            icon: Icons.photo_camera_back_rounded,
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasCover
                  ? _buildPreview(disabled: disabled, loading: loading)
                  : _buildPicker(disabled: disabled, loading: loading),
            ),
          ),

          if (hasCover) ...[
            const SizedBox(height: 8),
            Text(
              coverFile == null ? 'รูปเดิม' : fileName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RecipeFormStyle.muted,
                fontSize: 12.5,
              ),
            ),
          ],

          if (showImgCommuOption) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: RecipeFormStyle.fieldFill,
                borderRadius: BorderRadius.circular(
                  RecipeFormStyle.fieldRadius,
                ),
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: RecipeFormStyle.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    RecipeFormStyle.fieldRadius,
                  ),
                ),
                title: const Text(
                  'แสดงรูปในชุมชน',
                  style: TextStyle(
                    color: RecipeFormStyle.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'โชว์รูปเล็กใต้โพสต์ในหน้า Community',
                  style: TextStyle(color: RecipeFormStyle.muted, fontSize: 12),
                ),
                value: showImgCommu,
                onChanged: disabled
                    ? null
                    : (value) {
                        onShowImgCommuChanged(value ?? false);
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ยังไม่มีรูป: พื้นที่ใหญ่ให้แตะเลือก
  Widget _buildPicker({required bool disabled, required bool loading}) {
    return Material(
      color: RecipeFormStyle.fieldFill,
      child: InkWell(
        onTap: disabled ? null : onPickImage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: RecipeFormStyle.primary,
                      ),
                    )
                  : const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 28,
                      color: RecipeFormStyle.primary,
                    ),
            ),
            const SizedBox(height: 10),
            const Text(
              'เลือกรูปภาพ',
              style: TextStyle(
                color: RecipeFormStyle.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'JPG, PNG, WEBP หรือ GIF ไม่เกิน 10 MB',
              style: TextStyle(color: RecipeFormStyle.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // มีรูปแล้ว: รูปเต็มกรอบ + ปุ่มเปลี่ยน/ลบลอยอยู่มุมล่าง
  Widget _buildPreview({required bool disabled, required bool loading}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE9E6DE),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                size: 36,
                color: RecipeFormStyle.muted,
              ),
            );
          },
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Row(
            children: [
              _OverlayButton(
                onPressed: disabled ? null : onPickImage,
                tooltip: 'เปลี่ยนรูปภาพ',
                child: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: RecipeFormStyle.ink,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'เปลี่ยนรูปภาพ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              _OverlayButton(
                onPressed: disabled ? null : onRemoveImage,
                tooltip: 'ลบรูปภาพ',
                child: const Icon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage({required ImageErrorWidgetBuilder errorBuilder}) {
    final file = coverFile;
    if (file != null) {
      return Image.file(file, fit: BoxFit.cover, errorBuilder: errorBuilder);
    }
    return Image.network(
      coverUrl!,
      fit: BoxFit.cover,
      errorBuilder: errorBuilder,
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.onPressed,
    required this.tooltip,
    required this.child,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: IconTheme.merge(
              data: const IconThemeData(color: RecipeFormStyle.ink),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: RecipeFormStyle.ink,
                  fontSize: 13,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
